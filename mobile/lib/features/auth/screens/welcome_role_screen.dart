import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/screen_util.dart';
import '../../../localization/app_localizations.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/auth_provider.dart' show UserRole;
import '../../shared/widgets/language_switcher_pill.dart';

class WelcomeRoleScreen extends ConsumerWidget {
  const WelcomeRoleScreen({super.key});

  void _selectCustomer(BuildContext context, WidgetRef ref) {
    // Set a guest customer session locally
    ref.read(sessionProvider.notifier).setRole(UserRole.customer);
    // Bypass OTP completely, go straight to shop linking/scanning
    Navigator.of(context).pushNamedAndRemoveUntil('/customer/shop-link', (r) => false);
  }

  void _selectOwner(BuildContext context, WidgetRef ref) {
    ref.read(sessionProvider.notifier).setRole(UserRole.owner);
    // Owners must go through the Whitelisted OTP flow
    Navigator.of(context).pushNamed('/auth/phone');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.md),
              const Align(
                alignment: Alignment.centerRight,
                child: LanguageSwitcherPill(),
              ),
              const Spacer(flex: 2),
              
              Center(
                child: Container(
                  width: ScreenUtil.dp(96),
                  height: ScreenUtil.dp(96),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.lg),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                    size: ScreenUtil.dp(48),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xl),
              
              Text(
                t.t('authWelcomeTitle'), 
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                "How do you want to use MyKirana?",
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(flex: 3),
              
              ElevatedButton(
                onPressed: () => _selectCustomer(context, ref),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text('I am a Customer', style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: AppSpacing.lg),
              
              OutlinedButton(
                onPressed: () => _selectOwner(context, ref),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: const BorderSide(color: AppColors.primary, width: 2),
                ),
                child: const Text(
                  'I am a Shop Owner', 
                  style: TextStyle(fontSize: 18, color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
