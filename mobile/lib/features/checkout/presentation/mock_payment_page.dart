import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/common.dart';
import '../../cart/presentation/cart_cubit.dart';
import '../../orders/domain/order.dart';

/// Stand-in for the payment gateway while the backend uses PAYMENT_PROVIDER=dummy.
class MockPaymentPage extends StatefulWidget {
  const MockPaymentPage({required this.orderId, super.key});

  final int orderId;

  @override
  State<MockPaymentPage> createState() => _MockPaymentPageState();
}

class _MockPaymentPageState extends State<MockPaymentPage> {
  late final Future<Order> _order = sl<OrdersRepository>().detail(widget.orderId);
  bool _busy = false;
  bool _failed = false;

  Future<void> _confirm(bool success) async {
    setState(() => _busy = true);
    try {
      await sl<OrdersRepository>().confirmMockPayment(widget.orderId, success: success);
      if (!mounted) return;
      if (success) {
        context.read<CartCubit>().clear();
        context.go('/orders/${widget.orderId}?paid=1');
      } else {
        setState(() => _failed = true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentTitle)),
      body: FutureBuilder<Order>(
        future: _order,
        builder: (context, snapshot) {
          final order = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(l10n.paymentHint, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(l10n.paymentAmount, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Text(
                      order == null ? '…' : context.fmt.money(order.total),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Directionality(
                textDirection: TextDirection.ltr,
                child: Column(
                  children: [
                    TextField(
                      enabled: false,
                      decoration: InputDecoration(hintText: '4242 4242 4242 4242', prefixIcon: Icon(Icons.credit_card)),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(enabled: false, decoration: InputDecoration(hintText: '12/29')),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(enabled: false, decoration: InputDecoration(hintText: '123')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_failed) ...[
                InfoBanner(text: l10n.paymentFailed, tone: InfoTone.danger, icon: Icons.error_outline),
                const SizedBox(height: 16),
                FilledButton(onPressed: () => context.go('/cart'), child: Text(l10n.paymentBackToCart)),
              ] else ...[
                FilledButton(
                  onPressed: _busy || order == null ? null : () => _confirm(true),
                  child: Text(l10n.paymentSuccess),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy || order == null ? null : () => _confirm(false),
                  child: Text(l10n.paymentFail),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
