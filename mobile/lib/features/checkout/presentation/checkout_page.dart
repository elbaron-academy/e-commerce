import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/di.dart';
import '../../../app/theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_image.dart';
import '../../account/presentation/address_form_sheet.dart';
import '../../cart/presentation/cart_cubit.dart';
import '../../cart/presentation/widgets.dart';
import '../domain/delivery.dart';
import 'checkout_cubit.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.lang),
      create: (context) => CheckoutCubit(
        cart: context.read<CartCubit>(),
        cartRepository: sl(),
        delivery: sl(),
        addresses: sl(),
        orders: sl(),
      )..load(),
      child: BlocListener<CheckoutCubit, CheckoutState>(
        listenWhen: (a, b) => a.result == null && b.result != null,
        listener: (context, state) => _afterPlaced(context, state.result!),
        child: const _CheckoutView(),
      ),
    );
  }

  static Future<void> _afterPlaced(BuildContext context, ({dynamic order, String? paymentUrl}) result) async {
    final id = result.order.id as int;
    final url = result.paymentUrl;
    if (url == null) {
      context.go('/orders/$id?placed=1');
    } else if (url.startsWith('http')) {
      // Real gateway page (MOB-502: swap for the gateway SDK or a WebView once chosen).
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (context.mounted) context.go('/orders/$id');
    } else {
      context.pushReplacement(url);
    }
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cart = context.watch<CartCubit>().state;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkoutTitle)),
      body: cart.lines.isEmpty
          ? EmptyState(
              emoji: '🛒',
              title: l10n.checkoutEmptyCart,
              action: FilledButton(onPressed: () => context.go('/'), child: Text(l10n.commonStartShopping)),
            )
          : BlocBuilder<CheckoutCubit, CheckoutState>(
              builder: (context, state) {
                if (state.loading) return const Center(child: CircularProgressIndicator());
                if (state.loadError != null) {
                  return ErrorView(error: state.loadError!, onRetry: context.read<CheckoutCubit>().load);
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const _MethodSection(),
                    const SizedBox(height: 12),
                    if (state.isDelivery) ...[const _AddressSection(), const SizedBox(height: 12)],
                    const _SlotSection(),
                    const SizedBox(height: 12),
                    const _PaymentSection(),
                    const SizedBox(height: 12),
                    const _SummarySection(),
                  ],
                );
              },
            ),
      bottomNavigationBar: cart.lines.isEmpty ? null : const _PlaceOrderBar(),
    );
  }
}

class _MethodSection extends StatelessWidget {
  const _MethodSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<CheckoutCubit>().state;
    final cubit = context.read<CheckoutCubit>();
    final pickup = state.info?.pickup;
    return SectionCard(
      title: l10n.checkoutMethod,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final (method, icon, label) in [
                ('delivery', Icons.local_shipping_outlined, l10n.checkoutDelivery),
                if (state.info?.pickupEnabled ?? true) ('pickup', Icons.storefront_outlined, l10n.checkoutPickup),
              ]) ...[
                if (method == 'pickup') const SizedBox(width: 8),
                Expanded(
                  child: ChoiceTile(
                    selected: state.method == method,
                    onTap: () => cubit.selectMethod(method),
                    child: Row(
                      children: [
                        Icon(icon, color: AppColors.brand700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (!state.isDelivery && pickup != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.canvas, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pickup.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    '${pickup.address} · ${pickup.hours}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<CheckoutCubit>().state;
    final cubit = context.read<CheckoutCubit>();
    return SectionCard(
      title: l10n.checkoutAddress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.addresses.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(l10n.checkoutNoAddresses, style: const TextStyle(color: AppColors.muted)),
            ),
          for (final a in state.addresses) ...[
            ChoiceTile(
              selected: a.id == state.addressId,
              onTap: () => cubit.selectAddress(a.id),
              child: Row(
                children: [
                  Icon(
                    a.id == state.addressId ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: AppColors.brand600,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.isDefault ? '${a.title} · ${l10n.addressDefault}' : a.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          a.line,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: () async {
              final address = await showAddressForm(context);
              if (address != null) await cubit.addressAdded(address);
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.checkoutAddAddress),
          ),
        ],
      ),
    );
  }
}

class _SlotSection extends StatelessWidget {
  const _SlotSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final state = context.watch<CheckoutCubit>().state;
    final cubit = context.read<CheckoutCubit>();
    final days = state.days;
    final today = DateUtils.dateOnly(DateTime.now());
    String dayLabel(DateTime date) {
      final diff = DateUtils.dateOnly(date).difference(today).inDays;
      if (diff == 0) return l10n.checkoutToday;
      if (diff == 1) return l10n.checkoutTomorrow;
      return fmt.date(date, 'EEEE d MMM');
    }

    final slots = days.isEmpty ? const <Slot>[] : days[state.dayIndex.clamp(0, days.length - 1)].slots;
    return SectionCard(
      title: state.isDelivery ? l10n.checkoutTime : l10n.checkoutPickupTime,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final (i, d) in days.indexed)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(dayLabel(d.date)),
                      selected: i == state.dayIndex,
                      onSelected: (_) => cubit.selectDay(i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final s in slots.where((s) => s.express))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChoiceTile(
                selected: s.id == state.slotId,
                enabled: s.available,
                onTap: () => cubit.selectSlot(s.id),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: AppColors.accent500),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l10n.checkoutExpress, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.2,
            children: [
              for (final s in slots.where((s) => !s.express))
                ChoiceTile(
                  selected: s.id == state.slotId,
                  enabled: s.available,
                  onTap: () => cubit.selectSlot(s.id),
                  child: Center(
                    child: Text(
                      s.available
                          ? '${fmt.time(s.start)} – ${fmt.time(s.end)}'
                          : '${fmt.time(s.start)} – ${fmt.time(s.end)} · ${l10n.checkoutFull}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentSection extends StatefulWidget {
  const _PaymentSection();

  @override
  State<_PaymentSection> createState() => _PaymentSectionState();
}

class _PaymentSectionState extends State<_PaymentSection> {
  late final _notes = TextEditingController(text: context.read<CheckoutCubit>().state.notes);

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<CheckoutCubit>().state;
    final cubit = context.read<CheckoutCubit>();
    final quote = state.quote;
    final codOk = quote?.codAvailable ?? true;
    final options = [
      (
        'cod',
        Icons.payments_outlined,
        l10n.checkoutCod,
        codOk ? null : l10n.checkoutCodUnavailable(context.fmt.money(quote!.codLimit)),
        codOk,
      ),
      ('card', Icons.credit_card, l10n.checkoutCard, l10n.checkoutCardHint, true),
      ('wallet', Icons.account_balance_wallet_outlined, l10n.checkoutWallet, l10n.checkoutWalletHint, true),
    ];
    return SectionCard(
      title: l10n.checkoutPayment,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (id, icon, title, hint, enabled) in options) ...[
            ChoiceTile(
              selected: state.payment == id,
              enabled: enabled,
              onTap: () => cubit.selectPayment(id),
              child: Row(
                children: [
                  Icon(
                    state.payment == id ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: AppColors.brand600,
                  ),
                  const SizedBox(width: 10),
                  Icon(icon, color: AppColors.brand700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        if (hint != null) Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          TextField(
            controller: _notes,
            maxLines: 2,
            maxLength: 300,
            onChanged: cubit.setNotes,
            decoration: InputDecoration(
              labelText: '${l10n.checkoutNotes} (${l10n.commonOptional})',
              hintText: l10n.checkoutNotesPlaceholder,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cart = context.watch<CartCubit>().state;
    final state = context.watch<CheckoutCubit>().state;
    final quote = state.quote;
    return SectionCard(
      title: l10n.cartSummary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final line in cart.lines)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: SizedBox.square(
                      dimension: 46,
                      child: ProductImage(
                        emoji: line.emoji,
                        color: Color(line.color),
                        image: line.image,
                        emojiSize: 22,
                        radius: 23,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (quote == null)
            const Skeleton(height: 120)
          else
            OrderSummaryView(
              subtotal: quote.subtotal,
              total: quote.total,
              deliveryFee: quote.deliveryFee,
              couponDiscount: quote.couponDiscount,
              savings: quote.savings,
            ),
          if (quote != null && !quote.canCheckout && quote.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            InfoBanner(text: quote.warnings.first.message, icon: Icons.warning_amber_rounded),
          ],
        ],
      ),
    );
  }
}

class _PlaceOrderBar extends StatelessWidget {
  const _PlaceOrderBar();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<CheckoutCubit>().state;
    final total = state.quote?.total ?? 0;
    final label = state.placing
        ? l10n.checkoutPlacing
        : state.payment == 'cod'
        ? l10n.checkoutPlaceOrder
        : l10n.checkoutPayNow(context.fmt.money(total));
    final hint = state.isDelivery && state.address == null
        ? l10n.checkoutChooseAddress
        : state.slotId == null && !state.loading
        ? l10n.checkoutChooseSlot
        : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.placeError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  errorText(state.placeError!, l10n),
                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
                ),
              )
            else if (hint != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  hint,
                  style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
              ),
            FilledButton(
              onPressed: state.canPlace ? context.read<CheckoutCubit>().place : null,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
