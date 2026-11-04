import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rocket_market/features/cart/presentation/cart_cubit.dart';
import 'package:rocket_market/features/catalog/data/catalog_mappers.dart';
import 'package:rocket_market/features/catalog/presentation/widgets/product_card.dart';

import '../helpers.dart';

void main() {
  testWidgets('product card: add to cart turns into a quantity stepper', (tester) async {
    final product = productFromJson(fixture('product_white_eggs'));
    final repo = MemoryCartRepository();
    final cart = CartCubit(repo);
    await tester.pumpWidget(
      testApp(
        SizedBox(width: 180, height: 330, child: ProductCard(product: product)),
        cart: cart,
      ),
    );

    expect(find.text('White Eggs'), findsOneWidget);
    expect(find.text('85 ج.م'), findsOneWidget);
    expect(find.text('أضف'), findsOneWidget);

    await tester.tap(find.text('أضف'));
    await tester.pump();
    expect(cart.state.count, 1);
    expect(find.text('1'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget, reason: 'minus becomes a bin at the minimum');

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    expect(repo.lines.single.qty, 2);
  });

  testWidgets('out-of-stock products cannot be added', (tester) async {
    final quote = fixture('quote');
    final avocado = productFromJson(
      (quote['lines'] as List).cast<Json>().firstWhere((l) => l['sku'] == 'RK-0005-1')['product'] as Json,
    );
    await tester.pumpWidget(
      testApp(
        SizedBox(width: 180, height: 330, child: ProductCard(product: avocado)),
        locale: const Locale('en'),
      ),
    );
    expect(find.text('Out of stock'), findsWidgets);
    expect(find.text('Add'), findsNothing);
  });
}
