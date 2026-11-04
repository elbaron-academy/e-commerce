import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/l10n/l10n.dart';
import '../domain/order.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (order.status) {
      'pending_payment' => (const Color(0xFFFEF3C7), const Color(0xFF92400E)),
      'placed' || 'confirmed' => (const Color(0xFFE0F2FE), const Color(0xFF075985)),
      'preparing' => (const Color(0xFFEDE9FE), const Color(0xFF5B21B6)),
      'out_for_delivery' || 'ready_for_pickup' => (const Color(0xFFFFE3D2), AppColors.accent700),
      'delivered' => (AppColors.brand100, AppColors.brand800),
      _ => (AppColors.danger50, AppColors.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(
        orderStatusLabel(context.l10n, order.status, pickup: order.isPickup),
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Order progress: placed → confirmed → preparing → out for delivery → delivered.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final steps = order.timeline;
    return Column(
      children: [
        for (final (i, step) in steps.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: step.done ? AppColors.brand600 : Colors.white,
                          border: Border.all(color: step.done ? AppColors.brand600 : AppColors.line, width: 2),
                        ),
                        child: step.done ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(width: 2, color: steps[i + 1].done ? AppColors.brand500 : AppColors.line),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orderStatusLabel(context.l10n, step.status, pickup: order.isPickup),
                          style: TextStyle(
                            fontWeight: step.done ? FontWeight.w800 : FontWeight.w600,
                            color: step.done ? AppColors.ink : AppColors.muted,
                          ),
                        ),
                        if (step.at != null)
                          Text(
                            context.fmt.date(step.at!, 'h:mm a'),
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
