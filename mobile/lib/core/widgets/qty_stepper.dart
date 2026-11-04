import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../l10n/l10n.dart';

/// [− 1 kg +]. The minus turns into a bin at the minimum quantity.
class QtyStepper extends StatelessWidget {
  const QtyStepper({
    required this.label,
    required this.atMin,
    required this.atMax,
    required this.onIncrement,
    required this.onDecrement,
    this.height = 40,
    super.key,
  });

  final String label;
  final bool atMin;
  final bool atMax;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final double height;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.brand50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brand200),
      ),
      child: Row(
        children: [
          _StepButton(
            icon: atMin ? Icons.delete_outline : Icons.remove,
            tooltip: atMin ? l10n.productRemove : l10n.productDecrease,
            onPressed: onDecrement,
            size: height,
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brand800),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            tooltip: l10n.productIncrease,
            onPressed: atMax ? null : onIncrement,
            filled: true,
            size: height,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.size,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: filled ? AppColors.brand600 : Colors.transparent,
          foregroundColor: filled ? Colors.white : AppColors.brand800,
          disabledBackgroundColor: filled ? AppColors.brand600.withValues(alpha: 0.4) : null,
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}
