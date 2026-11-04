import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app.dart';
import '../../../app/di.dart';
import '../../../app/theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/load_state.dart';
import '../../../core/widgets/product_image.dart';
import '../../cart/presentation/cart_cubit.dart';
import '../../cart/presentation/widgets.dart';
import '../domain/order.dart';
import 'orders_widgets.dart';

enum OrderBanner { placed, paid }

/// Loads the order and keeps it fresh while it is on its way (MOB-603).
class OrderDetailCubit extends LoadCubit<Order> {
  OrderDetailCubit(OrdersRepository orders, int id) : super(() => orders.detail(id)) {
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      final order = state.data;
      if (order != null && !order.isFinished && _visible) load(silent: true);
    });
  }

  late final Timer _timer;
  bool _visible = true;

  // ignore: use_setters_to_change_properties
  void setVisible(bool visible) => _visible = visible;

  @override
  Future<void> close() {
    _timer.cancel();
    return super.close();
  }
}

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({required this.orderId, this.banner, super.key});

  final int orderId;
  final OrderBanner? banner;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> with WidgetsBindingObserver {
  late final OrderDetailCubit _cubit = OrderDetailCubit(sl(), widget.orderId)..load();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final visible = state == AppLifecycleState.resumed;
    _cubit.setVisible(visible);
    if (visible) _cubit.load(silent: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<OrderDetailCubit, LoadState<Order>>(
            builder: (_, state) => Text(state.data == null ? l10n.ordersTitle : l10n.ordersNumber(state.data!.number)),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () => _cubit.load(silent: true),
          child: LoadView<OrderDetailCubit, Order>(
            builder: (context, order) => _OrderView(order: order, banner: widget.banner),
          ),
        ),
      ),
    );
  }
}

class _OrderView extends StatelessWidget {
  const _OrderView({required this.order, required this.banner});

  final Order order;
  final OrderBanner? banner;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final slot = order.slot;
    final slotText = slot == null
        ? ''
        : slot.express
        ? l10n.checkoutExpress
        : '${slot.date == null ? '' : fmt.date(slot.date!, 'EEEE d MMM')} · ${fmt.time(slot.start)} – ${fmt.time(slot.end)}';
    final payment = switch (order.paymentMethod) {
      'card' => l10n.checkoutCard,
      'wallet' => l10n.checkoutWallet,
      _ => l10n.checkoutCod,
    };
    final tracking = order.status != 'cancelled' && order.status != 'pending_payment';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (banner != null) ...[
          InfoBanner(
            text: banner == OrderBanner.paid ? l10n.ordersPaid : l10n.ordersPlaced,
            icon: Icons.check_circle,
            tone: InfoTone.success,
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: Text(fmt.date(order.createdAt, 'd MMMM · h:mm a'), style: const TextStyle(color: AppColors.muted)),
            ),
            OrderStatusChip(order: order),
          ],
        ),
        const SizedBox(height: 12),
        if (tracking) ...[
          SectionCard(
            title: l10n.ordersTracking,
            child: OrderTimeline(order: order),
          ),
          const SizedBox(height: 12),
        ],
        SectionCard(
          title: '${l10n.ordersDetails} (${l10n.ordersItems('${order.items.length}')})',
          child: Column(
            children: [
              for (final (i, item) in order.items.indexed) ...[
                if (i > 0) const Divider(height: 16),
                Row(
                  children: [
                    SizedBox.square(
                      dimension: 48,
                      child: ProductImage(
                        emoji: item.emoji,
                        color: parseHexColor(item.color),
                        image: item.image,
                        emojiSize: 24,
                        radius: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            item.soldByWeight
                                ? fmt.qty(item.qty, byWeight: true)
                                : '${item.variantLabel} × ${fmt.number(item.qty)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Text(fmt.money(item.lineTotal), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Column(
            children: [
              _InfoRow(
                icon: order.isPickup ? Icons.storefront_outlined : Icons.location_on_outlined,
                label: order.isPickup ? l10n.ordersPickupFrom : l10n.ordersDeliverTo,
                value: order.address?.line ?? l10n.checkoutPickup,
              ),
              _InfoRow(icon: Icons.schedule, label: l10n.ordersSlot, value: slotText),
              _InfoRow(
                icon: order.paymentMethod == 'cod' ? Icons.payments_outlined : Icons.credit_card,
                label: l10n.ordersPaymentMethod,
                value: payment,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: OrderSummaryView(
            subtotal: order.subtotal,
            total: order.total,
            deliveryFee: order.deliveryFee,
            couponDiscount: order.couponDiscount,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {
            context.read<CartCubit>().addFromOrder(order.items);
            showMessage(l10n.ordersReordered);
            context.go('/cart');
          },
          icon: const Icon(Icons.replay),
          label: Text(l10n.ordersReorder),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => context.push('/chat?order=${order.id}'),
          icon: const Icon(Icons.chat_bubble_outline),
          label: Text(l10n.chatHelpOrder),
        ),
        if (!order.isFinished)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              l10n.ordersPullToRefresh,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.brand700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
