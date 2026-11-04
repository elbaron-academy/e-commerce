import '../../../core/network/api_client.dart';
import '../../account/domain/address.dart';
import '../domain/order.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  OrdersRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<List<Order>> list() async {
    final data = await _api.get<Map<String, dynamic>>('/orders/', query: {'page_size': 48});
    return [for (final o in data['results'] as List) orderFromJson(o as Map<String, dynamic>)];
  }

  @override
  Future<Order> detail(int id) async => orderFromJson(await _api.get<Map<String, dynamic>>('/orders/$id/'));

  @override
  Future<({Order order, String? paymentUrl})> place(PlaceOrderInput input) async {
    final data = await _api.post<Map<String, dynamic>>('/orders/', data: input.toJson());
    return (order: orderFromJson(data['order'] as Map<String, dynamic>), paymentUrl: data['payment_url'] as String?);
  }

  @override
  Future<Order> confirmMockPayment(int orderId, {required bool success}) async => orderFromJson(
    await _api.post<Map<String, dynamic>>(
      '/payments/mock/confirm/',
      data: {'order_id': orderId, 'result': success ? 'success' : 'failed'},
    ),
  );
}

Order orderFromJson(Map<String, dynamic> json) {
  double d(Object? v) => (v as num?)?.toDouble() ?? 0;
  final slot = json['slot'] as Map<String, dynamic>?;
  final address = json['address'] as Map<String, dynamic>?;
  return Order(
    id: json['id'] as int,
    number: json['number'] as String,
    status: json['status'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    method: json['method'] as String,
    paymentMethod: json['payment_method'] as String,
    paymentStatus: json['payment_status'] as String,
    items: [
      for (final i in json['items'] as List)
        OrderItem(
          sku: i['sku'] as String,
          slug: i['slug'] as String,
          name: i['name'] as String,
          variantLabel: i['variant_label'] as String,
          emoji: (i['emoji'] as String?) ?? '',
          color: (i['color'] as String?) ?? '',
          image: i['image'] as String?,
          qty: d(i['qty']),
          unitPrice: d(i['unit_price']),
          lineTotal: d(i['line_total']),
          soldByWeight: i['sold_by_weight'] as bool? ?? false,
        ),
    ],
    subtotal: d(json['subtotal']),
    couponDiscount: d(json['coupon_discount']),
    deliveryFee: d(json['delivery_fee']),
    total: d(json['total']),
    coupon: json['coupon'] as String?,
    notes: (json['notes'] as String?) ?? '',
    address: address == null ? null : Address.fromJson(address),
    slot: slot == null
        ? null
        : OrderSlot(
            date: slot['date'] == null ? null : DateTime.parse('${slot['date']}T12:00:00'),
            start: (slot['start'] as String?) ?? '',
            end: (slot['end'] as String?) ?? '',
            express: slot['express'] as bool? ?? false,
          ),
    timeline: [
      for (final t in json['timeline'] as List)
        TimelineStep(
          status: t['status'] as String,
          at: t['at'] == null ? null : DateTime.parse(t['at'] as String),
          done: t['done'] as bool,
        ),
    ],
  );
}
