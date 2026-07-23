import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/auth_provider.dart' show UserRole;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Rate App dialog
  void _showRateAppDialog() {
    final t = AppLocalizations.of(context);
    int selectedStars = 5;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t.t('rateTitle')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.t('appTagline'),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= selectedStars ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.accent,
                      size: 36,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        selectedStars = starIndex;
                      });
                    },
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.t('commonCancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t.t('rateThankYou')),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: Text(t.t('rateSubmit')),
            ),
          ],
        ),
      ),
    );
  }

  // Share App dialog
  void _shareApp() {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.t('settingsShare')),
        content: Text(t.t('shareMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.t('commonCancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(t.t('commonDone')),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: Text(t.t('commonConfirm')),
          ),
        ],
      ),
    );
  }

  // Generic Message Dialog (About, Privacy, Terms)
  void _showInfoDialog(String titleKey, String messageKey) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.t(titleKey)),
        content: Scrollbar(
          child: SingleChildScrollView(
            child: Text(
              t.t(messageKey),
              style: AppTextStyles.bodyLarge,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.t('commonDone')),
          ),
        ],
      ),
    );
  }

  // Language Switcher Options
  void _changeLanguage(String code) {
    ref.read(localeProvider.notifier).setLocale(Locale(code));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('settingsTitle')),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // ── LANGUAGE SELECTION ──
          Card(
            margin: EdgeInsets.only(bottom: AppSpacing.md),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.t('settingsLanguage'),
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _LanguageChip(
                        label: 'English',
                        selected: currentLocale.languageCode == 'en',
                        onTap: () => _changeLanguage('en'),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      _LanguageChip(
                        label: 'हिंदी',
                        selected: currentLocale.languageCode == 'hi',
                        onTap: () => _changeLanguage('hi'),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      _LanguageChip(
                        label: 'मराठी',
                        selected: currentLocale.languageCode == 'mr',
                        onTap: () => _changeLanguage('mr'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── GENERAL INFORMATION ──
          Card(
            margin: EdgeInsets.only(bottom: AppSpacing.md),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                  title: Text(t.t('settingsAbout'), style: AppTextStyles.bodyLarge),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => _showInfoDialog('settingsAbout', 'aboutMessage'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                  title: Text(t.t('settingsPrivacy'), style: AppTextStyles.bodyLarge),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => _showInfoDialog('settingsPrivacy', 'privacyMessage'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.gavel_rounded, color: AppColors.primary),
                  title: Text(t.t('settingsTerms'), style: AppTextStyles.bodyLarge),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => _showInfoDialog('settingsTerms', 'termsMessage'),
                ),
              ],
            ),
          ),

          // ── APP STORE INTERACTIONS ──
          Card(
            margin: EdgeInsets.only(bottom: AppSpacing.xl),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.share_rounded, color: AppColors.primary),
                  title: Text(t.t('settingsShare'), style: AppTextStyles.bodyLarge),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: _shareApp,
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.rate_review_outlined, color: AppColors.primary),
                  title: Text(t.t('settingsRate'), style: AppTextStyles.bodyLarge),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: _showRateAppDialog,
                ),
              ],
            ),
          ),

          // ── ACCOUNT & SESSION ACTIONS ──
          if (session.role == UserRole.owner)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: Text(t.t('settingsLogout'), style: const TextStyle(fontSize: 16)),
                onPressed: () => _confirmLogout(context),
              ),
            )
          else if (session.role == UserRole.customer)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: const Icon(Icons.storefront_rounded, color: AppColors.primary),
                label: Text(
                  t.t('settingsChangeShop'),
                  style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  ref.read(sessionProvider.notifier).clearLinkedShop();
                  Navigator.of(context).pushNamedAndRemoveUntil('/customer/shop-link', (r) => false);
                },
              ),
            ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) async {
    final t = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.t('accountSwitchConfirmTitle')),
        content: Text(t.t('accountSwitchConfirmBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.t('commonCancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.t('accountSwitchAction')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ref.read(sessionProvider.notifier).signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
    }
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
