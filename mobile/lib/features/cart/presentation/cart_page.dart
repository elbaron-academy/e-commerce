import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app.dart';
import '../../../app/di.dart';
import '../../../app/theme.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/qty_stepper.dart';
import '../../auth/presentation/session_cubit.dart';
import '../domain/cart.dart';
import '../domain/cart_repository.dart';
import 'cart_cubit.dart';
import 'widgets.dart';

class QuoteState extends Equatable {
  const QuoteState({this.quote, this.loading = false, this.offline = false, this.couponMessage, this.couponOk = false});

  final Quote? quote;
  final bool loading;
  final bool offline;
  final String? couponMessage;
  final bool couponOk;

  @override
  List<Object?> get props => [quote, loading, offline, couponMessage, couponOk];
}

/// Asks the server to price the cart whenever items, quantities or the coupon change.
class QuoteCubit extends Cubit<QuoteState> {
  QuoteCubit(this._cart, this._repository) : super(const QuoteState()) {
    _subscription = _cart.stream.map((s) => s.signature).distinct().listen((_) => _schedule());
    _schedule(immediately: true);
  }

  final CartCubit _cart;
  final CartRepository _repository;
  late final StreamSubscription<String> _subscription;
  Timer? _timer;

  void _schedule({bool immediately = false}) {
    _timer?.cancel();
    _timer = Timer(immediately ? Duration.zero : const Duration(milliseconds: 300), refresh);
  }

  Future<void> refresh() async {
    final cart = _cart.state;
    if (cart.lines.isEmpty) {
      emit(const QuoteState());
      return;
    }
    emit(QuoteState(quote: state.quote, loading: true, couponMessage: state.couponMessage, couponOk: state.couponOk));
    try {
      final quote = await _repository.quote(cart.items(withPrices: true), coupon: cart.coupon);
      if (isClosed) return;
      var message = state.couponMessage;
      var ok = state.couponOk;
      if (quote.coupon case final coupon?) {
        message = coupon.message;
        ok = coupon.valid;
        if (!coupon.valid) _cart.setCoupon(null);
      }
      emit(QuoteState(quote: quote, couponMessage: message, couponOk: ok));
      _cart.syncFromQuote(quote);
    } on ApiException catch (e) {
      if (isClosed) return;
      emit(
        QuoteState(
          quote: state.quote,
          offline: e.isNetwork,
          couponMessage: state.couponMessage,
          couponOk: state.couponOk,
        ),
      );
    }
  }

  void clearCouponMessage() => emit(QuoteState(quote: state.quote, offline: state.offline));

  @override
  Future<void> close() {
    _timer?.cancel();
    _subscription.cancel();
    return super.close();
  }
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.lang),
      create: (context) => QuoteCubit(context.read<CartCubit>(), sl()),
      child: const _CartView(),
    );
  }
}

class _CartView extends StatelessWidget {
  const _CartView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cart = context.watch<CartCubit>().state;
    return Scaffold(
      appBar: AppBar(
        title: Text(cart.count > 0 ? '${l10n.cartTitle} (${l10n.cartItems('${cart.count}')})' : l10n.cartTitle),
        actions: [
          if (cart.count > 0)
            IconButton(
              tooltip: l10n.cartClear,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => context.read<CartCubit>().clear(),
            ),
        ],
      ),
      body: cart.lines.isEmpty
          ? EmptyState(
              emoji: '🛒',
              title: l10n.cartEmpty,
              text: l10n.cartEmptyHint,
              action: FilledButton(onPressed: () => context.go('/'), child: Text(l10n.commonStartShopping)),
            )
          : BlocBuilder<QuoteCubit, QuoteState>(
              builder: (context, quoteState) {
                final quote = quoteState.quote;
                final unavailable = {
                  for (final l in quote?.lines ?? const <QuoteLine>[])
                    if (!l.available) l.sku,
                };
                final warnings = quote?.warnings.where((w) => w.code != 'min_order').toList() ?? const <QuoteWarning>[];
                final minOrder = quote?.warnings.where((w) => w.code == 'min_order').firstOrNull;
                return RefreshIndicator(
                  onRefresh: context.read<QuoteCubit>().refresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      FreeDeliveryBar(
                        subtotal: quote?.subtotal ?? cart.estimate,
                        threshold: quote?.freeDeliveryThreshold ?? 500,
                      ),
                      if (quoteState.offline) ...[
                        const SizedBox(height: 12),
                        InfoBanner(text: l10n.cartOfflineEstimate, icon: Icons.wifi_off, tone: InfoTone.dark),
                      ],
                      for (final w in warnings) ...[
                        const SizedBox(height: 12),
                        InfoBanner(
                          text: w.message,
                          icon: Icons.warning_amber_rounded,
                          action: w.code == 'unavailable'
                              ? TextButton(
                                  onPressed: () {
                                    for (final sku in unavailable) {
                                      context.read<CartCubit>().remove(sku);
                                    }
                                  },
                                  child: Text(l10n.cartRemoveUnavailable),
                                )
                              : null,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Card(
                        child: Column(
                          children: [
                            for (final (i, line) in cart.lines.indexed) ...[
                              if (i > 0) const Divider(),
                              _CartLineTile(
                                line: line,
                                quoteLine: quote?.line(line.sku),
                                unavailable: unavailable.contains(line.sku),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SectionCard(
                        title: l10n.cartSummary,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _CouponField(),
                            const SizedBox(height: 12),
                            OrderSummaryView(
                              subtotal: quote?.subtotal ?? cart.estimate,
                              total: quote?.total ?? cart.estimate,
                              deliveryFee: quote?.deliveryFee ?? 0,
                              couponDiscount: quote?.couponDiscount ?? 0,
                              savings: quote?.savings ?? 0,
                              deliveryLabel: l10n.cartDeliveryFrom,
                            ),
                            if (minOrder != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                minOrder.message,
                                style: const TextStyle(
                                  color: AppColors.warning800,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: cart.lines.isEmpty ? null : const _CheckoutBar(),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({required this.line, required this.quoteLine, required this.unavailable});

  final CartLine line;
  final QuoteLine? quoteLine;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fmt = context.fmt;
    final cart = context.read<CartCubit>();
    final total = quoteLine?.lineTotal ?? line.price * line.qty;
    return Container(
      color: unavailable ? AppColors.danger50.withValues(alpha: 0.5) : null,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push('/product/${line.slug}'),
            child: SizedBox.square(
              dimension: 76,
              child: ProductImage(emoji: line.emoji, color: Color(line.color), image: line.image, emojiSize: 36),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        line.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    InkWell(
                      onTap: () => cart.remove(line.sku),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.close, size: 18, color: AppColors.muted),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${line.variantLabel} · ${fmt.money(line.price)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                if (unavailable)
                  Text(
                    l10n.cartUnavailable,
                    style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w700),
                  )
                else if (quoteLine?.priceChanged ?? false)
                  Text(
                    l10n.cartPriceUpdated,
                    style: const TextStyle(fontSize: 12, color: AppColors.warning800, fontWeight: FontWeight.w700),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (!unavailable)
                      SizedBox(
                        width: 128,
                        child: QtyStepper(
                          height: 36,
                          label: fmt.qty(line.qty, byWeight: line.soldByWeight),
                          atMin: line.atMin,
                          atMax: line.atMax,
                          onIncrement: () {
                            if (!cart.increment(line.sku)) showMessage(l10n.productMaxReached);
                          },
                          onDecrement: () => cart.decrement(line.sku),
                        ),
                      ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(fmt.money(total), style: const TextStyle(fontWeight: FontWeight.w800)),
                        if (line.originalPrice > line.price)
                          Text(
                            fmt.money(line.originalPrice * line.qty),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponField extends StatefulWidget {
  const _CouponField();

  @override
  State<_CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<_CouponField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final coupon = context.select((CartCubit c) => c.state.coupon);
    final quote = context.watch<QuoteCubit>().state;
    if (coupon != null && quote.couponOk) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.brand50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.brand200),
        ),
        child: Row(
          children: [
            const Icon(Icons.sell_outlined, size: 18, color: AppColors.brand700),
            const SizedBox(width: 8),
            Text(
              coupon,
              style: const TextStyle(fontWeight: FontWeight.w800),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                quote.couponMessage ?? '',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.brand700),
              ),
            ),
            IconButton(
              tooltip: l10n.cartRemoveCoupon,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                _controller.clear();
                context.read<QuoteCubit>().clearCouponMessage();
                context.read<CartCubit>().setCoupon(null);
              },
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(hintText: l10n.cartCouponPlaceholder, isDense: true),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                final code = _controller.text.trim().toUpperCase();
                if (code.isEmpty) return;
                context.read<QuoteCubit>().clearCouponMessage();
                context.read<CartCubit>().setCoupon(code);
              },
              child: Text(l10n.cartApply),
            ),
          ],
        ),
        if (quote.couponMessage != null && !quote.couponOk)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              quote.couponMessage!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final quote = context.watch<QuoteCubit>().state;
    final loggedIn = context.select((SessionCubit s) => s.state.isLoggedIn);
    final total = quote.quote?.total ?? context.select<CartCubit, double>((c) => c.state.estimate);
    final enabled = !quote.offline && (quote.quote?.canCheckout ?? false);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: FilledButton(
          onPressed: enabled
              ? () => loggedIn
                    ? context.push('/checkout')
                    : context.push(Uri(path: '/login', queryParameters: {'redirect': '/checkout'}).toString())
              : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: Row(
            children: [
              Expanded(child: Text(loggedIn ? l10n.cartCheckout : l10n.cartLoginToCheckout)),
              Text(context.fmt.money(total)),
            ],
          ),
        ),
      ),
    );
  }
}
