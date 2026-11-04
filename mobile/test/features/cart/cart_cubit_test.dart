import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_market/features/cart/data/cart_repository_impl.dart';
import 'package:rocket_market/features/cart/presentation/cart_cubit.dart';
import 'package:rocket_market/features/catalog/data/catalog_mappers.dart';
import 'package:rocket_market/features/catalog/domain/entities.dart';
import 'package:rocket_market/features/orders/data/orders_repository_impl.dart';

import '../../helpers.dart';

void main() {
  final eggs = productFromJson(fixture('product_white_eggs'));
  final quote = quoteFromJson(fixture('quote'));
  final banana = quote.line('RK-0001-1')!.product; // sold by weight, 0.25 kg steps, 0.5 kg minimum
  final avocado = quote.line('RK-0005-1')!.product; // out of stock

  late MemoryCartRepository repo;
  setUp(() => repo = MemoryCartRepository());

  test('adds a product once, then increases the quantity', () {
    final cart = CartCubit(repo);
    expect(cart.add(eggs), isTrue);
    expect(cart.add(eggs), isTrue);
    expect(cart.state.count, 1);
    expect(cart.state.line('RK-0021-1')!.qty, 2);
    expect(repo.lines.single.qty, 2, reason: 'saved on every change');
  });

  test('weight items use 0.25 kg steps from 0.5 kg and are removed below the minimum', () {
    final cart = CartCubit(repo)..add(banana);
    expect(cart.state.line('RK-0001-1')!.qty, 0.5);
    cart.increment('RK-0001-1');
    expect(cart.state.line('RK-0001-1')!.qty, 0.75);
    cart
      ..decrement('RK-0001-1')
      ..decrement('RK-0001-1');
    expect(cart.state.lines, isEmpty);
  });

  test('refuses out-of-stock items and stops at the maximum', () {
    final cart = CartCubit(repo);
    expect(cart.add(avocado), isFalse);
    final shrimpLike = Product(
      id: 1,
      slug: 's',
      name: 'S',
      brand: '',
      image: null,
      emoji: '🦐',
      color: eggs.color,
      category: eggs.category,
      subcategory: null,
      unitLabel: 'kg',
      soldByWeight: true,
      qtyStep: 0.25,
      minQty: 0.5,
      maxQty: 0.75,
      price: 10,
      salePrice: null,
      discountPercent: 0,
      saleEndsAt: null,
      inStock: true,
      defaultSku: 'S-1',
      variants: const [
        Variant(sku: 'S-1', label: 'kg', price: 10, salePrice: null, inStock: true, stock: 0.75, maxQty: 0.75),
      ],
      tags: const [],
    );
    cart.add(shrimpLike);
    expect(cart.increment('S-1'), isTrue);
    expect(cart.increment('S-1'), isFalse);
    expect(cart.state.line('S-1')!.qty, 0.75);
  });

  test('restores the saved cart and coupon', () {
    CartCubit(repo)
      ..add(eggs)
      ..setCoupon('ROCKET10');
    final restored = CartCubit(repo);
    expect(restored.state.count, 1);
    expect(restored.state.coupon, 'ROCKET10');
  });

  test('takes prices and limits from the server quote', () {
    final cart = CartCubit(repo)..add(banana);
    cart.syncFromQuote(quote);
    final line = cart.state.line('RK-0001-1')!;
    expect(line.price, quote.line('RK-0001-1')!.unitPrice);
    expect(line.qty, quote.line('RK-0001-1')!.qty);
  });

  test('order again merges with what is already in the cart', () {
    final order = orderFromJson(fixture('order_create')['order'] as Json);
    final cart = CartCubit(repo)..add(banana);
    cart.addFromOrder(order.items);
    expect(cart.state.count, order.items.length);
    expect(cart.state.line('RK-0001-1')!.qty, 2.5);
  });

  blocTest<CartCubit, CartState>(
    'signature changes with items and coupon only',
    build: () => CartCubit(repo),
    act: (cart) => cart
      ..add(eggs)
      ..setCoupon('SAVE50')
      ..clear(),
    verify: (cart) => expect(cart.state.signature, '#'),
    expect: () => [
      isA<CartState>().having((s) => s.signature, 'signature', 'RK-0021-1:1.0#'),
      isA<CartState>().having((s) => s.coupon, 'coupon', 'SAVE50'),
      isA<CartState>().having((s) => s.lines, 'lines', isEmpty),
    ],
  );
}
