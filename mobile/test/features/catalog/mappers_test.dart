import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_market/features/cart/data/cart_repository_impl.dart';
import 'package:rocket_market/features/catalog/data/catalog_mappers.dart';
import 'package:rocket_market/features/orders/data/orders_repository_impl.dart';

import '../../helpers.dart';

/// Parses real responses from the Django API, so a contract change breaks a test.
void main() {
  test('home', () {
    final home = homeFromJson(fixture('home'));
    expect(home.banners, hasLength(3));
    expect(home.sections.map((s) => s.key), ['offers', 'best', 'fresh', 'dairy', 'new']);
    expect(home.sections.first.products.every((p) => p.tags.contains('offer')), isTrue);
  });

  test('category tree', () {
    final tree = [for (final c in fixtureList('categories')) categoryFromJson(c as Json)];
    expect(tree, hasLength(8));
    expect(tree.first.children, isNotEmpty);
    expect(tree.first.productCount, tree.first.children.fold<int>(0, (s, c) => s + c.productCount));
  });

  test('product with sizes and a sale', () {
    final product = productFromJson(fixture('product_white_eggs'));
    expect(product.name, 'White Eggs');
    expect(product.variants, hasLength(2));
    final big = product.variant('RK-0021-2');
    expect(big.price, 165);
    expect(big.salePrice, 155);
    expect(big.discountPercent, 6);
    expect(product.saleEndsAt, isNotNull);
    expect(product.description, isNotEmpty);
  });

  test('cart quote', () {
    final quote = quoteFromJson(fixture('quote'));
    expect(quote.lines, hasLength(3));
    expect(quote.canCheckout, isFalse);
    expect(quote.warnings.map((w) => w.code), containsAll(['unavailable', 'price_changed']));
    expect(quote.line('RK-0005-1')!.available, isFalse);
    expect(quote.coupon!.valid, isFalse);
    expect(quote.line('RK-0001-1')!.product.soldByWeight, isTrue);
  });

  test('order', () {
    final order = orderFromJson(fixture('order_create')['order'] as Json);
    expect(order.number, startsWith('RK-'));
    expect(order.status, 'placed');
    expect(order.total, 369.3);
    expect(order.address!.zoneName, isNotEmpty);
    expect(order.timeline.first.done, isTrue);
    expect(order.items.first.soldByWeight, isTrue);
  });
}
