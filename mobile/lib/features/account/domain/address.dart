class Address {
  const Address({
    required this.id,
    required this.label,
    required this.zone,
    required this.zoneName,
    required this.area,
    required this.street,
    required this.building,
    required this.floor,
    required this.apartment,
    required this.notes,
    required this.lat,
    required this.lng,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'] as int,
    label: (json['label'] as String?) ?? '',
    zone: json['zone'] as String,
    zoneName: (json['zone_name'] as String?) ?? '',
    area: json['area'] as String,
    street: json['street'] as String,
    building: json['building'] as String,
    floor: (json['floor'] as String?) ?? '',
    apartment: (json['apartment'] as String?) ?? '',
    notes: (json['notes'] as String?) ?? '',
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    isDefault: json['is_default'] as bool? ?? false,
  );

  final int id;
  final String label;
  final String zone;
  final String zoneName;
  final String area;
  final String street;
  final String building;
  final String floor;
  final String apartment;
  final String notes;
  final double? lat;
  final double? lng;
  final bool isDefault;

  String get title => label.isNotEmpty ? label : area;
  String get line => [street, building, area, zoneName].where((p) => p.isNotEmpty).join('، ');
}

class AddressInput {
  const AddressInput({
    required this.zone,
    required this.area,
    required this.street,
    required this.building,
    this.floor = '',
    this.apartment = '',
    this.label = '',
    this.notes = '',
    this.lat,
    this.lng,
  });

  final String zone;
  final String area;
  final String street;
  final String building;
  final String floor;
  final String apartment;
  final String label;
  final String notes;
  final double? lat;
  final double? lng;

  Map<String, dynamic> toJson() => {
    'zone': zone,
    'area': area,
    'street': street,
    'building': building,
    'floor': floor,
    'apartment': apartment,
    'label': label,
    'notes': notes,
    'lat': ?lat,
    'lng': ?lng,
  };
}

abstract interface class AddressRepository {
  Future<List<Address>> list();
  Future<Address> create(AddressInput input);
  Future<void> setDefault(int id);
  Future<void> delete(int id);
}
