import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/di.dart';
import '../../../app/theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../checkout/domain/delivery.dart';
import '../domain/address.dart';

/// Opens the "new address" form. Returns the saved address.
Future<Address?> showAddressForm(BuildContext context) => showModalBottomSheet<Address>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => const _AddressForm(),
);

class _AddressForm extends StatefulWidget {
  const _AddressForm();

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

enum _Locate { idle, busy, done, failed }

class _AddressFormState extends State<_AddressForm> {
  final _form = GlobalKey<FormState>();
  final _area = TextEditingController();
  final _street = TextEditingController();
  final _building = TextEditingController();
  final _floor = TextEditingController();
  final _apartment = TextEditingController();
  final _label = TextEditingController();
  final _notes = TextEditingController();
  late final Future<DeliveryInfo> _info = sl<DeliveryRepository>().info();
  String _zone = 'cairo';
  double? _lat;
  double? _lng;
  _Locate _locate = _Locate.idle;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_area, _street, _building, _floor, _apartment, _label, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  // TODO(FE-402/MOB-403): add a map picker; for now we store the GPS position.
  Future<void> _useLocation() async {
    setState(() => _locate = _Locate.busy);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception('Location is off');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Permission denied');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)),
      );
      setState(() {
        _lat = double.parse(position.latitude.toStringAsFixed(6));
        _lng = double.parse(position.longitude.toStringAsFixed(6));
        _locate = _Locate.done;
      });
    } catch (_) {
      if (mounted) setState(() => _locate = _Locate.failed);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final address = await sl<AddressRepository>().create(
        AddressInput(
          zone: _zone,
          area: _area.text.trim(),
          street: _street.text.trim(),
          building: _building.text.trim(),
          floor: _floor.text.trim(),
          apartment: _apartment.text.trim(),
          label: _label.text.trim(),
          notes: _notes.text.trim(),
          lat: _lat,
          lng: _lng,
        ),
      );
      if (mounted) Navigator.pop(context, address);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = errorText(error, context.l10n);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String? required(String? v) => (v == null || v.trim().isEmpty) ? '•' : null;
    Widget field(TextEditingController c, String label, {bool isRequired = false, TextInputType? keyboard}) =>
        TextFormField(
          controller: c,
          keyboardType: keyboard,
          validator: isRequired ? required : null,
          decoration: InputDecoration(labelText: isRequired ? label : '$label (${l10n.commonOptional})'),
        );
    final locateLabel = switch (_locate) {
      _Locate.idle => l10n.addressUseLocation,
      _Locate.busy => l10n.addressLocating,
      _Locate.done => l10n.addressLocated,
      _Locate.failed => l10n.addressLocationFailed,
    };
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _form,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text(l10n.addressTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _locate == _Locate.busy ? null : _useLocation,
              icon: Icon(_locate == _Locate.done ? Icons.check : Icons.my_location),
              label: Text(locateLabel),
              style: _locate == _Locate.done
                  ? OutlinedButton.styleFrom(
                      backgroundColor: AppColors.brand50,
                      foregroundColor: AppColors.brand700,
                      side: const BorderSide(color: AppColors.brand200),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            FutureBuilder<DeliveryInfo>(
              future: _info,
              builder: (context, snapshot) => DropdownButtonFormField<String>(
                initialValue: _zone,
                decoration: InputDecoration(labelText: l10n.addressZone),
                items: [
                  for (final z in snapshot.data?.zones ?? const <Zone>[])
                    DropdownMenuItem(
                      value: z.id,
                      child: Text('${z.name} · ${l10n.addressDeliveryFee(context.fmt.money(z.fee))}'),
                    ),
                  if (snapshot.data == null) DropdownMenuItem(value: _zone, child: Text(l10n.commonLoading)),
                ],
                onChanged: (v) => setState(() => _zone = v ?? _zone),
              ),
            ),
            const SizedBox(height: 12),
            field(_area, l10n.addressArea, isRequired: true),
            const SizedBox(height: 12),
            field(_street, l10n.addressStreet, isRequired: true),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: field(_building, l10n.addressBuilding, isRequired: true)),
                const SizedBox(width: 8),
                Expanded(child: field(_floor, l10n.addressFloor, keyboard: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: field(_apartment, l10n.addressApartment)),
              ],
            ),
            const SizedBox(height: 12),
            field(_label, l10n.addressLabel),
            const SizedBox(height: 12),
            field(_notes, l10n.addressNotes),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.addressSave)),
          ],
        ),
      ),
    );
  }
}
