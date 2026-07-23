import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

/// Large, glanceable balance card — red when owing, green when clear.
/// Used on both the owner's per-customer detail screen and the
/// customer's own "My Udhari" screen, so the color language stays
/// consistent across both sides of the app.
class UdhariBalanceCard extends StatelessWidget {
  const UdhariBalanceCard({
    super.key,
    required this.balance,
    required this.label,
    required this.clearLabel,
  });

  final double balance;
  final String label; // e.g. "Total owed" / "You owe"
  final String clearLabel; // e.g. "All clear!"

  bool get _isClear => balance <= 0;

  @override
  Widget build(BuildContext context) {
    final bg = _isClear ? AppColors.udhariClearBg : AppColors.udhariOwingBg;
    final fg = _isClear ? AppColors.udhariClear : AppColors.udhariOwing;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isClear ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
                color: fg,
                size: 18,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                _isClear ? clearLabel : label,
                style: AppTextStyles.label.copyWith(color: fg),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          if (!_isClear)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                '₹${balance.toStringAsFixed(0)}',
                key: ValueKey(balance),
                style: AppTextStyles.balanceAmount.copyWith(color: fg),
              ),
            ),
        ],
      ),
    );
  }
}

