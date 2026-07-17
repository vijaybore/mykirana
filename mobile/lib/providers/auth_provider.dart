import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStep { phoneInput, otpVerify, roleSelect, done }

enum UserRole { owner, customer }

class AuthState {
  const AuthState({
    this.step = AuthStep.phoneInput,
    this.phoneNumber = '',
    this.isLoading = false,
    this.errorMessage,
    this.role,
    this.name,
    this.verificationId,
    this.resendCooldownSeconds = 0,
  });

  final AuthStep step;
  final String phoneNumber;
  final bool isLoading;
  final String? errorMessage;
  final UserRole? role;
  final String? name;
  final String? verificationId;
  final int resendCooldownSeconds;

  AuthState copyWith({
    AuthStep? step,
    String? phoneNumber,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    UserRole? role,
    String? name,
    String? verificationId,
    int? resendCooldownSeconds,
  }) {
    return AuthState(
      step: step ?? this.step,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      role: role ?? this.role,
      name: name ?? this.name,
      verificationId: verificationId ?? this.verificationId,
      resendCooldownSeconds:
          resendCooldownSeconds ?? this.resendCooldownSeconds,
    );
  }
}

/// Handles the phone -> OTP -> role-select flow.
/// Firebase Auth wiring (verifyPhoneNumber / signInWithCredential) plugs
/// into sendOtp() / verifyOtp() below — stubbed with a mock delay for now
/// so the UI is fully testable before backend/Firebase project keys exist.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      phoneNumber: phoneNumber,
    );
    try {
      // TODO: replace with FirebaseAuth.instance.verifyPhoneNumber(...)
      await Future.delayed(const Duration(seconds: 1));
      state = state.copyWith(
        isLoading: false,
        step: AuthStep.otpVerify,
        verificationId: 'mock-verification-id',
        resendCooldownSeconds: 30,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'errorGeneric',
      );
    }
  }

  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO: replace with FirebaseAuth signInWithCredential using
      // PhoneAuthProvider.credential(verificationId, otp)
      await Future.delayed(const Duration(milliseconds: 800));
      if (otp.length != 6) {
        throw Exception('invalid');
      }
      // TODO: check backend if user already has a role -> skip to done
      state = state.copyWith(isLoading: false, step: AuthStep.roleSelect);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'authOtpError',
      );
    }
  }

  void tickResendCooldown() {
    if (state.resendCooldownSeconds > 0) {
      state = state.copyWith(
        resendCooldownSeconds: state.resendCooldownSeconds - 1,
      );
    }
  }

  Future<void> resendOtp() async {
    if (state.resendCooldownSeconds > 0) return;
    await sendOtp(state.phoneNumber);
  }

  void goBackToPhoneInput() {
    state = state.copyWith(step: AuthStep.phoneInput, clearError: true);
  }

  Future<void> selectRole(UserRole role, String name) async {
    state = state.copyWith(isLoading: true);
    try {
      // TODO: POST /users { phone, role, name } to backend
      await Future.delayed(const Duration(milliseconds: 600));
      state = state.copyWith(
        isLoading: false,
        role: role,
        name: name,
        step: AuthStep.done,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'errorGeneric');
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
