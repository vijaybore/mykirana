import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/screen_util.dart';
import '../../../localization/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../shared/widgets/language_switcher_pill.dart';

class PhoneInputScreen extends ConsumerStatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  ConsumerState<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSendOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      ref.read(authProvider.notifier).sendOtp(_phoneController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final authState = ref.watch(authProvider);

    // Navigate forward once state flips to otpVerify
    ref.listen(authProvider, (previous, next) {
      if (next.step == AuthStep.otpVerify &&
          previous?.step != AuthStep.otpVerify) {
        Navigator.of(context).pushNamed('/auth/otp');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.md),
                const Align(
                  alignment: Alignment.centerRight,
                  child: LanguageSwitcherPill(),
                ),
                const Spacer(flex: 2),

                // Logo / brand mark
                Container(
                  width: ScreenUtil.dp(72),
                  height: ScreenUtil.dp(72),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppSpacing.lg),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                    size: ScreenUtil.dp(36),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),

                Text(t.t('authWelcomeTitle'), style: AppTextStyles.h1),
                SizedBox(height: AppSpacing.sm),
                Text(
                  t.t('authWelcomeSubtitle'),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                SizedBox(height: AppSpacing.xxl),

                Text(t.t('authPhoneLabel'), style: AppTextStyles.label),
                SizedBox(height: AppSpacing.sm),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  style: AppTextStyles.bodyLarge,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    hintText: t.t('authPhoneHint'),
                    prefixIcon: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: Text('+91', style: AppTextStyles.bodyLarge),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length != 10) {
                      return t.t('authPhoneError');
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleSendOtp(),
                ),

                if (authState.errorMessage != null) ...[
                  SizedBox(height: AppSpacing.md),
                  if (authState.errorMessage == 'PAYWALL')
                    Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              "Subscription required to register a shop: ₹500/month.",
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      t.t(authState.errorMessage!),
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
                    ),
                ],

                const Spacer(flex: 3),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleSendOtp,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(t.t('authSendOtp')),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                Center(
                  child: Text(
                    t.t('authTermsNotice'),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

