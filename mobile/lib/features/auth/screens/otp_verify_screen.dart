import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../../../providers/auth_provider.dart';

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
        Navigator.of(context).pushNamed('/auth/role');
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text(t.t('authOtpTitle'), style: AppTextStyles.h1),
              const SizedBox(height: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.md),

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

              const SizedBox(height: AppSpacing.xxl),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final hasError = authState.errorMessage != null;
                  return SizedBox(
                    width: 46,
                    height: 56,
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
                const SizedBox(height: AppSpacing.md),
                Text(
                  t.t(authState.errorMessage!),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xl),

              if (authState.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: CircularProgressIndicator(strokeWidth: 2.5),
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
