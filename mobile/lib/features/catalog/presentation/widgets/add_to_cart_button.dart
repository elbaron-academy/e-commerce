import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/app.dart';
import '../../../../app/theme.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/qty_stepper.dart';
import '../../../cart/presentation/cart_cubit.dart';
import '../../domain/entities.dart';

/// "+ Add" button that turns into a quantity stepper once the item is in the cart.
class AddToCartButton extends StatelessWidget {
  const AddToCartButton({required this.product, this.sku, this.large = false, super.key});

  final Product product;
  final String? sku;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final variant = product.variant(sku);
    final line = context.select((CartCubit c) => c.state.line(variant.sku));
    final height = large ? 52.0 : 40.0;

    if (!variant.inStock) {
      return SizedBox(
        height: height,
        child: FilledButton(
          onPressed: null,
          style: FilledButton.styleFrom(
            disabledBackgroundColor: AppColors.canvas,
            disabledForegroundColor: AppColors.muted,
          ),
          child: Text(l10n.productOutOfStock),
        ),
      );
    }
    if (line == null) {
      return SizedBox(
        height: height,
        child: FilledButton.icon(
          onPressed: () {
            if (!context.read<CartCubit>().add(product, variant)) showMessage(l10n.productMaxReached);
          },
          style: FilledButton.styleFrom(
            minimumSize: Size(0, height),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          icon: const Icon(Icons.add, size: 20),
          label: Text(large ? l10n.productAddToCart : l10n.productAdd),
        ),
      );
    }
    return QtyStepper(
      height: height,
      label: context.fmt.qty(line.qty, byWeight: line.soldByWeight),
      atMin: line.atMin,
      atMax: line.atMax,
      onIncrement: () {
        if (!context.read<CartCubit>().increment(line.sku)) showMessage(l10n.productMaxReached);
      },
      onDecrement: () => context.read<CartCubit>().decrement(line.sku),
    );
  }
}
