import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/order_models.dart';

/// placed -> ready -> completed, shown as three connected dots so the
/// customer (and owner) can see progress at a glance without reading text.
/// A cancelled order is a separate terminal state, not "step 4" of this
/// progression, so it renders as its own badge instead of forcing all
/// three dots to look complete.
class OrderStatusStepper extends StatelessWidget {
  const OrderStatusStepper({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (status == OrderStatus.cancelled) {
      return Row(
        children: [
          const Icon(Icons.cancel_outlined, size: 18, color: AppColors.danger),
          SizedBox(width: AppSpacing.xs),
          Text(
            t.t('orderStatusCancelled'),
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.danger, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }

    final steps = [
      (OrderStatus.placed, t.t('orderStatusPlaced')),
      (OrderStatus.ready, t.t('orderStatusReady')),
      (OrderStatus.completed, t.t('orderStatusCompleted')),
    ];

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _StepDot(
            label: steps[i].$2,
            done: steps[i].$1.stepIndex <= status.stepIndex,
          ),
          if (i != steps.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: steps[i].$1.stepIndex < status.stepIndex
                    ? AppColors.stepDone
                    : AppColors.stepPending,
              ),
            ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.label, required this.done});
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: done ? AppColors.stepDone : AppColors.stepPending,
            shape: BoxShape.circle,
          ),
          child: done
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : null,
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: done ? AppColors.textPrimary : AppColors.textMuted,
            fontWeight: done ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
