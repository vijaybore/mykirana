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

class _PhoneInputScreenState extends ConsumerState<PhoneInputScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _fadeCtrl.dispose();
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
    final size = MediaQuery.of(context).size;

    // Navigate forward once state flips to otpVerify
    ref.listen(authProvider, (previous, next) {
      if (next.step == AuthStep.otpVerify &&
          previous?.step != AuthStep.otpVerify) {
        Navigator.of(context).pushNamed('/auth/otp');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Decorative top gradient arc
          Positioned(
            top: -size.height * 0.1,
            left: -size.width * 0.2,
            right: -size.width * 0.2,
            child: Container(
              height: size.height * 0.45,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.12),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: LanguageSwitcherPill(),
                      ),
                      const Spacer(flex: 2),

                      // Logo mark
                      Container(
                        width: ScreenUtil.dp(80),
                        height: ScreenUtil.dp(80),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: ScreenUtil.dp(40),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xl),

                      // Title
                      Text(
                        'MyKirana Owner',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.t('authWelcomeSubtitle'),
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),

                      SizedBox(height: AppSpacing.xxl),

                      // Phone field
                      Text(t.t('authPhoneLabel'), style: AppTextStyles.label),
                      SizedBox(height: AppSpacing.sm),

                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        autofocus: true,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontSize: 18,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          hintText: t.t('authPhoneHint'),
                          hintStyle: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.normal,
                            letterSpacing: 0.5,
                          ),
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            child: Text(
                              '+91',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                                color: AppColors.primary, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.danger),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 18),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length != 10) {
                            return t.t('authPhoneError');
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _handleSendOtp(),
                      ),

                      // Error card
                      if (authState.errorMessage != null) ...[
                        SizedBox(height: AppSpacing.md),
                        _ErrorCard(
                          isUnauthorized:
                              authState.errorMessage == 'authUnauthorizedOwner',
                          message: authState.errorMessage == 'authUnauthorizedOwner'
                              ? t.t('authUnauthorizedOwner')
                              : t.t(authState.errorMessage!),
                        ),
                      ],

                      const Spacer(flex: 3),

                      // Send OTP button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: authState.isLoading ? null : _handleSendOtp,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor:
                                AppColors.primary.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      t.t('authSendOtp'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
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
          ),
        ],
      ),
    );
  }
}

/// Styled error card — shows lock icon for unauthorized, warning icon otherwise.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.isUnauthorized, required this.message});
  final bool isUnauthorized;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isUnauthorized ? Icons.lock_outline_rounded : Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.danger,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
