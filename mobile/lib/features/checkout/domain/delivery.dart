class Zone {
  const Zone({required this.id, required this.name, required this.fee});

  final String id;
  final String name;
  final double fee;
}

class PickupPoint {
  const PickupPoint({required this.name, required this.address, required this.hours});

  final String name;
  final String address;
  final String hours;
}

class DeliveryInfo {
  const DeliveryInfo({
    required this.zones,
    required this.freeDeliveryThreshold,
    required this.minOrder,
    required this.pickup,
    required this.pickupEnabled,
  });

  final List<Zone> zones;
  final double freeDeliveryThreshold;
  final double minOrder;
  final PickupPoint pickup;
  final bool pickupEnabled;
}

class Slot {
  const Slot({
    required this.id,
    required this.start,
    required this.end,
    required this.available,
    required this.express,
  });

  final String id;
  final String start;
  final String end;
  final bool available;
  final bool express;
}

class SlotDay {
  const SlotDay({required this.date, required this.slots});

  final DateTime date;
  final List<Slot> slots;
}

abstract interface class DeliveryRepository {
  Future<DeliveryInfo> info();
  Future<List<SlotDay>> slots();
}
