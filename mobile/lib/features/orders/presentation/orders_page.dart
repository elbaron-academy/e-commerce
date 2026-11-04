import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/load_state.dart';
import '../../../core/widgets/product_image.dart';
import '../../auth/presentation/session_cubit.dart';
import '../domain/order.dart';
import 'orders_widgets.dart';

class OrdersCubit extends LoadCubit<List<Order>> {
  OrdersCubit(OrdersRepository orders) : super(orders.list);
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.select((SessionCubit s) => s.state.user);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ordersTitle)),
      body: user == null
          ? EmptyState(
              emoji: '📦',
              title: l10n.ordersEmpty,
              text: l10n.accountSignInPrompt,
              action: FilledButton(onPressed: () => context.push('/login'), child: Text(l10n.headerLogin)),
            )
          : BlocProvider(
              key: ValueKey('${context.lang}-${user.id}'),
              create: (_) => OrdersCubit(sl())..load(),
              child: Builder(
                builder: (context) => RefreshIndicator(
                  onRefresh: () => context.read<OrdersCubit>().load(silent: true),
                  child: LoadView<OrdersCubit, List<Order>>(
                    builder: (context, orders) => orders.isEmpty
                        ? ListView(
                            children: [
                              EmptyState(
                                emoji: '📦',
                                title: l10n.ordersEmpty,
                                text: l10n.ordersEmptyHint,
                                action: FilledButton(
                                  onPressed: () => context.go('/'),
                                  child: Text(l10n.commonStartShopping),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: orders.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, i) => _OrderCard(order: orders[i]),
                          ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await context.push('/orders/${order.id}');
          if (context.mounted) context.read<OrdersCubit>().load(silent: true);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.ordersNumber(order.number), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  OrderStatusChip(order: order),
                ],
              ),
              Text(
                fmt.date(order.createdAt, 'd MMMM · h:mm a'),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final item in order.items.take(5))
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 4),
                      child: SizedBox.square(
                        dimension: 40,
                        child: ProductImage(
                          emoji: item.emoji,
                          color: parseHexColor(item.color),
                          image: item.image,
                          emojiSize: 20,
                          radius: 20,
                        ),
                      ),
                    ),
                  if (order.items.length > 5)
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.canvas,
                      child: Text(
                        '+${order.items.length - 5}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  const Spacer(),
                  Text(fmt.money(order.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
