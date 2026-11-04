import 'cart.dart';

abstract interface class CartRepository {
  ({List<CartLine> lines, String? coupon}) load();
  Future<void> save(List<CartLine> lines, String? coupon);
  Future<Quote> quote(List<CartItemInput> items, {String? coupon, String? zone, String method = 'delivery'});
}
