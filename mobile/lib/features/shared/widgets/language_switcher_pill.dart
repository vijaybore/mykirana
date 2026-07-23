import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../providers/locale_provider.dart';

/// Small language toggle shown on the welcome/phone-entry screen so
/// people can pick their language before doing anything else — most
/// village users will recognize हिंदी/मराठी script instantly even if
/// they can't read the English label next to it.
class LanguageSwitcherPill extends ConsumerWidget {
  const LanguageSwitcherPill({super.key});

  static const _options = [
    (code: 'en', label: 'English'),
    (code: 'hi', label: 'हिंदी'),
    (code: 'mr', label: 'मराठी'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _options.map((opt) {
          final selected = currentLocale.languageCode == opt.code;
          return GestureDetector(
            onTap: () => ref
                .read(localeProvider.notifier)
                .setLocale(Locale(opt.code)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                opt.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
