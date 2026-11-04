import '../../../core/network/api_client.dart';
import '../domain/delivery.dart';

class DeliveryRepositoryImpl implements DeliveryRepository {
  DeliveryRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<DeliveryInfo> info() async {
    final json = await _api.get<Map<String, dynamic>>('/delivery/info/');
    final pickup = json['pickup'] as Map<String, dynamic>;
    return DeliveryInfo(
      zones: [
        for (final z in json['zones'] as List)
          Zone(id: z['id'] as String, name: z['name'] as String, fee: (z['fee'] as num).toDouble()),
      ],
      freeDeliveryThreshold: (json['free_delivery_threshold'] as num).toDouble(),
      minOrder: (json['min_order'] as num).toDouble(),
      pickup: PickupPoint(
        name: pickup['name'] as String,
        address: pickup['address'] as String,
        hours: pickup['hours'] as String,
      ),
      pickupEnabled: json['pickup_enabled'] as bool? ?? true,
    );
  }

  @override
  Future<List<SlotDay>> slots() async {
    final data = await _api.get<List<dynamic>>('/delivery/slots/');
    return [
      for (final d in data)
        SlotDay(
          date: DateTime.parse('${d['date']}T12:00:00'),
          slots: [
            for (final s in d['slots'] as List)
              Slot(
                id: s['id'] as String,
                start: s['start'] as String,
                end: s['end'] as String,
                available: s['available'] as bool,
                express: s['express'] as bool,
              ),
          ],
        ),
    ];
  }
}
