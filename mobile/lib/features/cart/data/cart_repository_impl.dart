import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/storage/key_value_store.dart';
import '../../catalog/data/catalog_mappers.dart';
import '../domain/cart.dart';
import '../domain/cart_repository.dart';

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._api, this._store);

  static const _key = 'rk_cart_v1';

  final ApiClient _api;
  final KeyValueStore _store;

  @override
  ({List<CartLine> lines, String? coupon}) load() {
    try {
      final raw = _store.getString(_key);
      if (raw == null) return (lines: const [], coupon: null);
      final data = jsonDecode(raw) as Json;
      return (
        lines: [for (final l in data['lines'] as List) CartLine.fromJson(l as Json)],
        coupon: data['coupon'] as String?,
      );
    } catch (_) {
      return (lines: const [], coupon: null);
    }
  }

  @override
  Future<void> save(List<CartLine> lines, String? coupon) => _store.setString(
    _key,
    jsonEncode({
      'lines': [for (final l in lines) l.toJson()],
      'coupon': coupon,
    }),
  );

  @override
  Future<Quote> quote(List<CartItemInput> items, {String? coupon, String? zone, String method = 'delivery'}) async {
    final json = await _api.post<Json>(
      '/cart/quote/',
      data: {
        'items': [for (final i in items) i.toJson()],
        'coupon': coupon,
        'zone': zone,
        'method': method,
      },
    );
    return quoteFromJson(json);
  }
}

Quote quoteFromJson(Json json) {
  double d(Object? v) => (v as num?)?.toDouble() ?? 0;
  final coupon = json['coupon'] as Json?;
  return Quote(
    lines: [
      for (final l in json['lines'] as List)
        QuoteLine(
          sku: l['sku'] as String,
          qty: d(l['qty']),
          available: l['available'] as bool,
          maxQty: d(l['max_qty']),
          unitPrice: d(l['unit_price']),
          originalUnitPrice: d(l['original_unit_price']),
          lineTotal: d(l['line_total']),
          priceChanged: l['price_changed'] as bool,
          variantLabel: l['variant_label'] as String,
          product: productFromJson(l['product'] as Json),
        ),
    ],
    subtotal: d(json['subtotal']),
    savings: d(json['savings']),
    couponDiscount: d(json['coupon_discount']),
    deliveryFee: d(json['delivery_fee']),
    total: d(json['total']),
    minOrder: d(json['min_order']),
    freeDeliveryThreshold: d(json['free_delivery_threshold']),
    codAvailable: json['cod_available'] as bool,
    codLimit: d(json['cod_limit']),
    coupon: coupon == null
        ? null
        : CouponResult(
            code: coupon['code'] as String,
            valid: coupon['valid'] as bool,
            message: coupon['message'] as String,
          ),
    warnings: [
      for (final w in json['warnings'] as List)
        QuoteWarning(code: w['code'] as String, message: w['message'] as String),
    ],
    canCheckout: json['can_checkout'] as bool,
  );
}
