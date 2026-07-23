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

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
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
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpValue => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
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
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.step == AuthStep.roleSelect &&
          previous?.step != AuthStep.roleSelect) {
        // If the user already chose 'Shop Owner' on the welcome screen,
        // skip the role-select form and auto-complete their login as owner.
        final sessionRole = ref.read(sessionProvider).role;
        if (sessionRole == UserRole.owner) {
          ref.read(authProvider.notifier).selectRole(UserRole.owner, 'Owner');
        } else {
          Navigator.of(context).pushNamed('/auth/role');
        }
      }
      // When login completes (either via auto-owner flow from welcome screen
      // or via backend returning-user detection), navigate to the right home.
      if (next.step == AuthStep.done && previous?.step != AuthStep.done) {
        // Persist session for the returning user.
        ref.read(sessionProvider.notifier).setUser(
              userId: next.userId!,
              role: next.role!,
            );
        final route = next.role == UserRole.owner
            ? '/owner/shop-setup'
            : '/customer/shop-link';
        Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
      }
      // Clear boxes on a fresh error so the user can retype immediately
      if (next.errorMessage != null && previous?.errorMessage == null) {
        _clearOtp();
      }
      if (next.resendCooldownSeconds == 30 &&
          previous?.resendCooldownSeconds != 30) {
        _startResendTimer();
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(authProvider.notifier).goBackToPhoneInput();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.lg),
              Text(t.t('authOtpTitle'), style: AppTextStyles.h1),
              SizedBox(height: AppSpacing.sm),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(text: '${t.t('authOtpSubtitle')} '),
                    TextSpan(
                      text: '+91 ${authState.phoneNumber}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md),

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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final hasError = authState.errorMessage != null;
                  return SizedBox(
                    width: ScreenUtil.dp(46),
                    height: ScreenUtil.dp(56),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: AppTextStyles.h2,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: hasError
                                ? AppColors.danger
                                : AppColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (value) => _onDigitChanged(index, value),
                    ),
                  );
                }),
              ),

              if (authState.errorMessage != null) ...[
                SizedBox(height: AppSpacing.md),
                Text(
                  t.t(authState.errorMessage!),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ],

              SizedBox(height: AppSpacing.xl),

              if (authState.isLoading)
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: const CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              else
                Center(
                  child: authState.resendCooldownSeconds > 0
                      ? Text(
                          t.t(
                            'authOtpResendIn',
                            params: {
                              'seconds': authState.resendCooldownSeconds
                                  .toString(),
                            },
                          ),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                        )
                      : GestureDetector(
                          onTap: () =>
                              ref.read(authProvider.notifier).resendOtp(),
                          child: Text(
                            t.t('authOtpResend'),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
