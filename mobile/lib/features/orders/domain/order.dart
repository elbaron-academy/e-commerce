import '../../account/domain/address.dart';
import '../../cart/domain/cart.dart';

class OrderItem {
  const OrderItem({
    required this.sku,
    required this.slug,
    required this.name,
    required this.variantLabel,
    required this.emoji,
    required this.color,
    required this.image,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    required this.soldByWeight,
  });

  final String sku;
  final String slug;
  final String name;
  final String variantLabel;
  final String emoji;
  final String color;
  final String? image;
  final double qty;
  final double unitPrice;
  final double lineTotal;
  final bool soldByWeight;
}

class TimelineStep {
  const TimelineStep({required this.status, required this.at, required this.done});

  final String status;
  final DateTime? at;
  final bool done;
}

class OrderSlot {
  const OrderSlot({required this.date, required this.start, required this.end, required this.express});

  final DateTime? date;
  final String start;
  final String end;
  final bool express;
}

class Order {
  const Order({
    required this.id,
    required this.number,
    required this.status,
    required this.createdAt,
    required this.method,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.items,
    required this.subtotal,
    required this.couponDiscount,
    required this.deliveryFee,
    required this.total,
    required this.coupon,
    required this.notes,
    required this.address,
    required this.slot,
    required this.timeline,
  });

  final int id;
  final String number;
  final String status;
  final DateTime createdAt;
  final String method;
  final String paymentMethod;
  final String paymentStatus;
  final List<OrderItem> items;
  final double subtotal;
  final double couponDiscount;
  final double deliveryFee;
  final double total;
  final String? coupon;
  final String notes;
  final Address? address;
  final OrderSlot? slot;
  final List<TimelineStep> timeline;

  bool get isPickup => method == 'pickup';
  bool get isFinished => status == 'delivered' || status == 'cancelled';
}

class PlaceOrderInput {
  const PlaceOrderInput({
    required this.items,
    required this.method,
    required this.slotId,
    required this.paymentMethod,
    this.addressId,
    this.coupon,
    this.notes = '',
  });

  final List<CartItemInput> items;
  final String method;
  final String slotId;
  final String paymentMethod;
  final int? addressId;
  final String? coupon;
  final String notes;

  Map<String, dynamic> toJson() => {
    'items': [for (final i in items) i.toJson()],
    'method': method,
    'slot_id': slotId,
    'payment_method': paymentMethod,
    'address_id': addressId,
    'coupon': coupon,
    'notes': notes,
  };
}

abstract interface class OrdersRepository {
  Future<List<Order>> list();
  Future<Order> detail(int id);

  /// Places the order. `paymentUrl` is set for card/wallet payments.
  Future<({Order order, String? paymentUrl})> place(PlaceOrderInput input);

  /// Test gateway only (backend PAYMENT_PROVIDER=dummy).
  Future<Order> confirmMockPayment(int orderId, {required bool success});
}
