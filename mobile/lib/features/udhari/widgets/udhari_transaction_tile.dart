import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/udhari_models.dart';

/// One row in a udhari history timeline. Credit entries (goods taken)
/// and payments are visually distinguished with color + icon + sign,
/// so a glance down the list tells the story without reading dates.
class UdhariTransactionTile extends StatelessWidget {
  const UdhariTransactionTile({
    super.key,
    required this.transaction,
    this.pendingSync = false,
  });

  final UdhariTransaction transaction;
  final bool pendingSync;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isCredit = transaction.type == UdhariType.credit;
    final color = isCredit ? AppColors.udhariOwing : AppColors.udhariClear;
    final sign = isCredit ? '+' : '−';
    final label = isCredit
        ? t.t('udhariCreditGiven')
        : t.t('udhariPaymentReceived');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.north_east_rounded : Icons.south_west_rounded,
              size: 18,
              color: color,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
                    if (pendingSync) ...[
                      SizedBox(width: AppSpacing.xs),
                      const Icon(Icons.cloud_off_rounded,
                          size: 14, color: AppColors.textMuted),
                    ],
                  ],
                ),
                if (transaction.note != null && transaction.note!.isNotEmpty)
                  Text(
                    transaction.note!,
                    style: AppTextStyles.bodySmall,
                  ),
                Text(
                  DateFormat('d MMM, h:mm a').format(transaction.createdAt),
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Text(
            '$sign₹${transaction.amount.toStringAsFixed(0)}',
            style: AppTextStyles.priceMedium.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

