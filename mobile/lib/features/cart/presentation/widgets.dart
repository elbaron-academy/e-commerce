import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/l10n/l10n.dart';

class FreeDeliveryBar extends StatelessWidget {
  const FreeDeliveryBar({required this.subtotal, required this.threshold, super.key});

  final double subtotal;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final remaining = (threshold - subtotal).clamp(0, double.infinity);
    final progress = threshold <= 0 ? 1.0 : (subtotal / threshold).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brand50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brand100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 20, color: AppColors.brand800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  remaining > 0
                      ? l10n.cartFreeDeliveryLeft(context.fmt.money(remaining))
                      : l10n.cartFreeDeliveryReached,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brand800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 400),
              builder: (_, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: AppColors.brand100,
                color: AppColors.brand500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtotal, coupon, delivery and total rows.
class OrderSummaryView extends StatelessWidget {
  const OrderSummaryView({
    required this.subtotal,
    required this.total,
    required this.deliveryFee,
    this.couponDiscount = 0,
    this.savings = 0,
    this.deliveryLabel,
    super.key,
  });

  final double subtotal;
  final double total;
  final double deliveryFee;
  final double couponDiscount;
  final double savings;
  final String? deliveryLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    Widget row(String label, String value, {Color? color, bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color ?? (bold ? AppColors.ink : AppColors.muted),
                fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                fontSize: bold ? 16 : 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.ink,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(l10n.cartSubtotal, fmt.money(subtotal)),
        if (couponDiscount > 0) row(l10n.cartCoupon, '- ${fmt.money(couponDiscount)}', color: AppColors.brand700),
        row(
          deliveryLabel ?? l10n.cartDelivery,
          deliveryFee > 0 ? fmt.money(deliveryFee) : l10n.commonFree,
          color: deliveryFee > 0 ? null : AppColors.brand700,
        ),
        const Divider(height: 20),
        row(l10n.cartTotal, fmt.money(total), bold: true),
        if (savings > 0)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: AppColors.accent50, borderRadius: BorderRadius.circular(10)),
            child: Text(
              '🎉 ${l10n.cartSavings} ${fmt.money(savings)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.accent700, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        const SizedBox(height: 6),
        Text(l10n.cartVatIncluded, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }
}
