import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../account/domain/address.dart';
import '../../cart/domain/cart.dart';
import '../../cart/domain/cart_repository.dart';
import '../../cart/presentation/cart_cubit.dart';
import '../../orders/domain/order.dart';
import '../domain/delivery.dart';

class CheckoutState extends Equatable {
  const CheckoutState({
    this.loading = true,
    this.loadError,
    this.info,
    this.allDays = const [],
    this.addresses = const [],
    this.method = 'delivery',
    this.addressId,
    this.dayIndex = 0,
    this.slotId,
    this.payment = 'cod',
    this.notes = '',
    this.quote,
    this.placing = false,
    this.placeError,
    this.result,
  });

  final bool loading;
  final Object? loadError;
  final DeliveryInfo? info;
  final List<SlotDay> allDays;
  final List<Address> addresses;
  final String method;
  final int? addressId;
  final int dayIndex;
  final String? slotId;
  final String payment;
  final String notes;
  final Quote? quote;
  final bool placing;
  final Object? placeError;
  final ({Order order, String? paymentUrl})? result;

  bool get isDelivery => method == 'delivery';

  Address? get address => addresses.where((a) => a.id == addressId).firstOrNull;

  /// Express delivery isn't offered for pickup; days with no free slot are hidden.
  List<SlotDay> get days => [
    for (final d in allDays)
      if (d.slots.where((s) => s.available && (isDelivery || !s.express)).isNotEmpty)
        SlotDay(
          date: d.date,
          slots: [
            for (final s in d.slots)
              if (isDelivery || !s.express) s,
          ],
        ),
  ];

  bool get canPlace =>
      !placing && quote != null && quote!.canCheckout && slotId != null && (!isDelivery || address != null);

  CheckoutState copyWith({
    bool? loading,
    Object? Function()? loadError,
    DeliveryInfo? info,
    List<SlotDay>? allDays,
    List<Address>? addresses,
    String? method,
    int? Function()? addressId,
    int? dayIndex,
    String? Function()? slotId,
    String? payment,
    String? notes,
    Quote? Function()? quote,
    bool? placing,
    Object? Function()? placeError,
    ({Order order, String? paymentUrl})? Function()? result,
  }) => CheckoutState(
    loading: loading ?? this.loading,
    loadError: loadError != null ? loadError() : this.loadError,
    info: info ?? this.info,
    allDays: allDays ?? this.allDays,
    addresses: addresses ?? this.addresses,
    method: method ?? this.method,
    addressId: addressId != null ? addressId() : this.addressId,
    dayIndex: dayIndex ?? this.dayIndex,
    slotId: slotId != null ? slotId() : this.slotId,
    payment: payment ?? this.payment,
    notes: notes ?? this.notes,
    quote: quote != null ? quote() : this.quote,
    placing: placing ?? this.placing,
    placeError: placeError != null ? placeError() : this.placeError,
    result: result != null ? result() : this.result,
  );

  @override
  List<Object?> get props => [
    loading,
    loadError,
    info,
    allDays,
    addresses,
    method,
    addressId,
    dayIndex,
    slotId,
    payment,
    notes,
    quote,
    placing,
    placeError,
    result,
  ];
}

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit({
    required this._cart,
    required this._cartRepository,
    required this._delivery,
    required this._addresses,
    required this._orders,
  }) : super(const CheckoutState());

  final CartCubit _cart;
  final CartRepository _cartRepository;
  final DeliveryRepository _delivery;
  final AddressRepository _addresses;
  final OrdersRepository _orders;

  Future<void> load() async {
    emit(state.copyWith(loading: true, loadError: () => null));
    try {
      final results = await Future.wait([_delivery.info(), _delivery.slots(), _addresses.list()]);
      final addresses = results[2] as List<Address>;
      final preferred = addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull;
      emit(
        state.copyWith(
          loading: false,
          info: results[0] as DeliveryInfo,
          allDays: results[1] as List<SlotDay>,
          addresses: addresses,
          addressId: () => preferred?.id,
        ),
      );
      _keepValidSlot();
      await refreshQuote();
    } catch (error) {
      emit(state.copyWith(loading: false, loadError: () => error));
    }
  }

  Future<void> refreshQuote() async {
    if (_cart.state.lines.isEmpty) return;
    try {
      final quote = await _cartRepository.quote(
        _cart.state.items(),
        coupon: _cart.state.coupon,
        zone: state.isDelivery ? state.address?.zone : null,
        method: state.method,
      );
      var payment = state.payment;
      if (!quote.codAvailable && payment == 'cod') payment = 'card';
      if (!isClosed) emit(state.copyWith(quote: () => quote, payment: payment));
    } catch (_) {
      // Keep the previous totals; placing the order re-checks everything on the server.
    }
  }

  void selectMethod(String method) {
    if (method == state.method) return;
    emit(state.copyWith(method: method));
    _keepValidSlot();
    refreshQuote();
  }

  void selectAddress(int id) {
    emit(state.copyWith(addressId: () => id));
    refreshQuote();
  }

  Future<void> addressAdded(Address address) async {
    final addresses = await _addresses.list().catchError((_) => [...state.addresses, address]);
    emit(state.copyWith(addresses: addresses, addressId: () => address.id));
    await refreshQuote();
  }

  void selectDay(int index) => emit(state.copyWith(dayIndex: index));

  void selectSlot(String id) => emit(state.copyWith(slotId: () => id));

  void selectPayment(String payment) => emit(state.copyWith(payment: payment));

  void setNotes(String notes) => emit(state.copyWith(notes: notes));

  Future<void> place() async {
    if (!state.canPlace) return;
    emit(state.copyWith(placing: true, placeError: () => null));
    try {
      final result = await _orders.place(
        PlaceOrderInput(
          items: _cart.state.items(),
          coupon: _cart.state.coupon,
          method: state.method,
          addressId: state.isDelivery ? state.addressId : null,
          slotId: state.slotId!,
          paymentMethod: state.payment,
          notes: state.notes,
        ),
      );
      // Cash orders are final now; online payments clear the cart once paid.
      if (result.paymentUrl == null) _cart.clear();
      emit(state.copyWith(placing: false, result: () => result));
    } catch (error) {
      emit(state.copyWith(placing: false, placeError: () => error));
      await refreshQuote();
    }
  }

  void _keepValidSlot() {
    final days = state.days;
    final all = [for (final d in days) ...d.slots];
    if (all.any((s) => s.id == state.slotId && s.available)) return;
    final first = all.where((s) => s.available).firstOrNull;
    final dayIndex = days.indexWhere((d) => d.slots.any((s) => s.id == first?.id));
    emit(state.copyWith(slotId: () => first?.id, dayIndex: dayIndex < 0 ? 0 : dayIndex));
  }
}
