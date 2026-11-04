import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../l10n/l10n.dart';

class PriceTag extends StatelessWidget {
  const PriceTag({required this.price, this.salePrice, this.large = false, super.key});

  final double price;
  final double? salePrice;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final fmt = context.fmt;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 8,
      children: [
        Text(
          fmt.money(salePrice ?? price),
          style: TextStyle(
            fontSize: large ? 24 : 15,
            fontWeight: FontWeight.w800,
            color: salePrice != null ? AppColors.accent600 : AppColors.ink,
          ),
        ),
        if (salePrice != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              fmt.money(price),
              style: TextStyle(
                fontSize: large ? 15 : 12,
                color: AppColors.muted,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.muted,
              ),
            ),
          ),
      ],
    );
  }
}
