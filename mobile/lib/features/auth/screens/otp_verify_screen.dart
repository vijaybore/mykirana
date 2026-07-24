import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/screen_util.dart';
import '../../../localization/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/session_provider.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  void _startResendTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(authProvider.notifier).tickResendCooldown();
      if (ref.read(authProvider).resendCooldownSeconds <= 0) {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeCtrl.dispose();
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _otpValue => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    // Handle paste: if 6 digits pasted into first field
    if (value.length == 6 && index == 0) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = value[i];
      }
      _focusNodes[5].requestFocus();
      FocusScope.of(context).unfocus();
      ref.read(authProvider.notifier).verifyOtp(value);
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_otpValue.length == 6) {
      FocusScope.of(context).unfocus();
      ref.read(authProvider.notifier).verifyOtp(_otpValue);
    }
  }

  void _clearOtp() {
    for (final c in _controllers) { c.clear(); }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final authState = ref.watch(authProvider);
    final hasError = authState.errorMessage != null;

    ref.listen(authProvider, (previous, next) {
      if (next.step == AuthStep.roleSelect &&
          previous?.step != AuthStep.roleSelect) {
        final sessionRole = ref.read(sessionProvider).role;
        if (sessionRole == UserRole.owner) {
          ref.read(authProvider.notifier).selectRole(UserRole.owner, 'Owner');
        } else {
          Navigator.of(context).pushNamed('/auth/role');
        }
      }
      if (next.step == AuthStep.done && previous?.step != AuthStep.done) {
        ref.read(sessionProvider.notifier).setUser(
              userId: next.userId!,
              role: next.role!,
            );
        if (next.role == UserRole.owner) {
          if (next.shopId != null &&
              next.shopName != null &&
              next.shopCode != null) {
            // Owner already has a shop on the server — hydrate the local
            // session so any screen can read shopId/code without an extra
            // round-trip, then go straight to the dashboard.
            ref.read(sessionProvider.notifier).setLinkedShop(
                  shopId: next.shopId!,
                  shopName: next.shopName!,
                  shopCode: next.shopCode!,
                );
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/owner/dashboard', (r) => false);
          } else {
            // New owner — no shop yet, let them create one.
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/owner/shop-setup', (r) => false);
          }
        } else {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/customer/shop-link', (r) => false);
        }
      }
      if (next.errorMessage != null && previous?.errorMessage == null) {
        _clearOtp();
      }
      if (next.resendCooldownSeconds == 30 &&
          previous?.resendCooldownSeconds != 30) {
        _startResendTimer();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimary,
          onPressed: () {
            ref.read(authProvider.notifier).goBackToPhoneInput();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.md),

                // OTP sent icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.message_outlined,
                      color: AppColors.primary, size: 26),
                ),
                SizedBox(height: AppSpacing.lg),

                Text(t.t('authOtpTitle'), style: AppTextStyles.h1),
                SizedBox(height: AppSpacing.sm),

                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(text: '${t.t('authOtpSubtitle')} '),
                      TextSpan(
                        text: '+91 ${authState.phoneNumber}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.sm),

                GestureDetector(
                  onTap: () {
                    ref.read(authProvider.notifier).goBackToPhoneInput();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    t.t('authOtpChangeNumber'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                SizedBox(height: AppSpacing.xxl),

                // OTP boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: ScreenUtil.dp(48),
                      height: ScreenUtil.dp(58),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: hasError
                              ? [
                                  BoxShadow(
                                    color: AppColors.danger.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: index == 0 ? 6 : 1,
                          style: AppTextStyles.h2.copyWith(
                            color: hasError
                                ? AppColors.danger
                                : AppColors.textPrimary,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: hasError
                                ? AppColors.dangerLight
                                : AppColors.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: hasError
                                    ? AppColors.danger
                                    : AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: hasError
                                    ? AppColors.danger
                                    : AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: hasError
                                    ? AppColors.danger
                                    : AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) => _onDigitChanged(index, value),
                        ),
                      ),
                    );
                  }),
                ),

                // Error message
                if (hasError) ...[
                  SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.t(authState.errorMessage!),
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: AppSpacing.xl),

                // Loading / Resend
                Center(
                  child: authState.isLoading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Verifying...',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      : authState.resendCooldownSeconds > 0
                          ? RichText(
                              text: TextSpan(
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.textMuted),
                                children: [
                                  const TextSpan(text: 'Resend OTP in '),
                                  TextSpan(
                                    text: '${authState.resendCooldownSeconds}s',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : TextButton.icon(
                              onPressed: () =>
                                  ref.read(authProvider.notifier).resendOtp(),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(t.t('authOtpResend')),
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
