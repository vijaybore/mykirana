import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/udhari_models.dart';

/// Quick-add bottom sheet — feels fast (no full-page navigation) per
/// the interactive-design direction. Owner picks credit or payment,
/// types an amount, optionally a note, and saves.
class AddUdhariEntrySheet extends StatefulWidget {
  const AddUdhariEntrySheet({
    super.key,
    required this.customerName,
    required this.onSave,
  });

  final String customerName;
  final Future<void> Function(UdhariType type, double amount, String? note)
      onSave;

  static Future<void> show(
    BuildContext context, {
    required String customerName,
    required Future<void> Function(UdhariType type, double amount, String? note)
        onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddUdhariEntrySheet(
        customerName: customerName,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddUdhariEntrySheet> createState() => _AddUdhariEntrySheetState();
}

class _AddUdhariEntrySheetState extends State<AddUdhariEntrySheet> {
  UdhariType _type = UdhariType.credit;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);
    await widget.onSave(
      _type,
      amount,
      _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            Text(widget.customerName, style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.lg),

            // Tappable type cards, not a dropdown — matches "e-commerce
            // interactive" direction (payment mode selector pattern).
            Row(
              children: [
                Expanded(
                  child: _TypeCard(
                    icon: Icons.north_east_rounded,
                    label: t.t('udhariAddCredit'),
                    color: AppColors.udhariOwing,
                    selected: _type == UdhariType.credit,
                    onTap: () => setState(() => _type = UdhariType.credit),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _TypeCard(
                    icon: Icons.south_west_rounded,
                    label: t.t('udhariRecordPayment'),
                    color: AppColors.udhariClear,
                    selected: _type == UdhariType.payment,
                    onTap: () => setState(() => _type = UdhariType.payment),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(t.t('udhariAmountLabel'), style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.h2,
              decoration: InputDecoration(
                prefixText: '₹ ',
                hintText: t.t('udhariAmountHint'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text(t.t('udhariNoteLabel'), style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _noteController,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(hintText: t.t('udhariNoteHint')),
            ),
            const SizedBox(height: AppSpacing.xl),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _handleSave,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(t.t('commonSave')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AppColors.textSecondary),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: selected ? color : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

