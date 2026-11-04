import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../catalog/domain/entities.dart';
import '../../orders/domain/order.dart';
import '../domain/cart.dart';
import '../domain/cart_repository.dart';

class CartState extends Equatable {
  const CartState({this.lines = const [], this.coupon});

  final List<CartLine> lines;
  final String? coupon;

  int get count => lines.length;
  double get estimate => lines.fold(0, (sum, l) => sum + l.price * l.qty);

  CartLine? line(String sku) {
    for (final l in lines) {
      if (l.sku == sku) return l;
    }
    return null;
  }

  /// Changes whenever the items, quantities or coupon change (not on price refreshes).
  String get signature => '${lines.map((l) => '${l.sku}:${l.qty}').join('|')}#${coupon ?? ''}';

  List<CartItemInput> items({bool withPrices = false}) => [
    for (final l in lines) CartItemInput(sku: l.sku, qty: l.qty, expectedPrice: withPrices ? l.price : null),
  ];

  @override
  List<Object?> get props => [lines, coupon];
}

/// The cart lives on the device (works offline). Every change is saved right away
/// and the UI updates instantly; the server prices it on the cart screen (MOB-401).
class CartCubit extends Cubit<CartState> {
  CartCubit(CartRepository repository) : _repository = repository, super(_initial(repository));

  final CartRepository _repository;

  static CartState _initial(CartRepository repository) {
    final saved = repository.load();
    return CartState(lines: saved.lines, coupon: saved.coupon);
  }

  static double _round(double value) => (value * 1000).roundToDouble() / 1000;

  /// Returns false when the item is out of stock or already at its maximum.
  bool add(Product product, [Variant? variant]) {
    final v = variant ?? product.variant();
    if (!v.inStock || v.maxQty <= 0) return false;
    if (state.line(v.sku) != null) return increment(v.sku);
    _save([...state.lines, CartLine.fromProduct(product, v)]);
    return true;
  }

  bool increment(String sku) {
    final line = state.line(sku);
    if (line == null || line.atMax) return false;
    _replace(line.copyWith(qty: _round(line.qty + line.step)));
    return true;
  }

  void decrement(String sku) {
    final line = state.line(sku);
    if (line == null) return;
    final next = _round(line.qty - line.step);
    if (next < line.min - 1e-9) {
      remove(sku);
    } else {
      _replace(line.copyWith(qty: next));
    }
  }

  void remove(String sku) => _save([
    for (final l in state.lines)
      if (l.sku != sku) l,
  ]);

  void clear() => _save(const [], coupon: null, clearCoupon: true);

  void setCoupon(String? code) => _save(state.lines, coupon: code, clearCoupon: code == null);

  /// "Order again": puts the items of a past order back in the cart.
  void addFromOrder(List<OrderItem> items) {
    final lines = [...state.lines];
    for (final item in items) {
      final index = lines.indexWhere((l) => l.sku == item.sku);
      if (index >= 0) {
        final line = lines[index];
        lines[index] = line.copyWith(qty: _round((line.qty + item.qty).clamp(line.min, line.max)));
        continue;
      }
      lines.add(
        CartLine(
          sku: item.sku,
          slug: item.slug,
          qty: item.qty,
          name: item.name,
          variantLabel: item.variantLabel,
          emoji: item.emoji,
          color: 0xFFEEF2EF,
          image: item.image,
          price: item.unitPrice,
          originalPrice: item.unitPrice,
          soldByWeight: item.soldByWeight,
          step: item.soldByWeight ? 0.25 : 1,
          min: item.soldByWeight ? 0.5 : 1,
          max: item.soldByWeight ? 5 : 20,
        ),
      );
    }
    _save(lines);
  }

  /// Updates the saved snapshots with the server's names, prices and limits.
  void syncFromQuote(Quote quote) {
    var changed = false;
    final lines = <CartLine>[];
    for (final line in state.lines) {
      final q = quote.line(line.sku);
      if (q == null) {
        lines.add(line);
        continue;
      }
      final updated = line.copyWith(
        name: q.product.name,
        variantLabel: q.variantLabel,
        price: q.unitPrice,
        originalPrice: q.originalUnitPrice,
        max: q.maxQty,
        qty: q.available && q.qty != line.qty ? q.qty : null,
      );
      changed =
          changed ||
          updated.price != line.price ||
          updated.qty != line.qty ||
          updated.name != line.name ||
          updated.max != line.max;
      lines.add(updated);
    }
    if (changed) _save(lines);
  }

  void _replace(CartLine line) => _save([for (final l in state.lines) l.sku == line.sku ? line : l]);

  void _save(List<CartLine> lines, {String? coupon, bool clearCoupon = false}) {
    final next = CartState(lines: lines, coupon: clearCoupon ? null : (coupon ?? state.coupon));
    emit(next);
    _repository.save(next.lines, next.coupon);
  }
}
