import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

/// Maps a caught error to a localization key. Connection failures
/// (timeout, unreachable host) get their own message so the person
/// isn't left staring at a generic "something went wrong" when the
/// real problem is "the backend isn't running / isn't reachable".
String errorKeyFor(Object e) {
  if (e is ApiException) {
    if (e.isConnectionError) return 'errorNoServerConnection';
    return e.message;
  }
  return e.toString().replaceAll('Exception: ', '');
}

enum AuthStep { phoneInput, otpVerify, roleSelect, done }

enum UserRole { owner, customer }

extension UserRoleX on UserRole {
  String get apiValue => this == UserRole.owner ? 'owner' : 'customer';

  static UserRole? fromApi(String? value) {
    if (value == 'owner') return UserRole.owner;
    if (value == 'customer') return UserRole.customer;
    return null;
  }
}

class AuthState {
  const AuthState({
    this.step = AuthStep.phoneInput,
    this.phoneNumber = '',
    this.isLoading = false,
    this.errorMessage,
    this.role,
    this.name,
    this.userId,
    this.verificationId,
    this.resendCooldownSeconds = 0,
    // Populated when the owner already has a shop, so navigation
    // listeners can go straight to the dashboard instead of shop-setup.
    this.shopId,
    this.shopName,
    this.shopCode,
  });

  final AuthStep step;
  final String phoneNumber;
  final bool isLoading;
  final String? errorMessage;
  final UserRole? role;
  final String? name;
  final String? userId;
  final String? verificationId;
  final int resendCooldownSeconds;
  final String? shopId;
  final String? shopName;
  final String? shopCode;

  AuthState copyWith({
    AuthStep? step,
    String? phoneNumber,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    UserRole? role,
    String? name,
    String? userId,
    String? verificationId,
    int? resendCooldownSeconds,
    String? shopId,
    String? shopName,
    String? shopCode,
  }) {
    return AuthState(
      step: step ?? this.step,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      role: role ?? this.role,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      verificationId: verificationId ?? this.verificationId,
      resendCooldownSeconds:
          resendCooldownSeconds ?? this.resendCooldownSeconds,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      shopCode: shopCode ?? this.shopCode,
    );
  }
}

/// Handles the phone -> OTP -> role-select flow.
/// Firebase Auth wiring (verifyPhoneNumber / signInWithCredential) plugs
/// into sendOtp() / verifyOtp() below — stubbed with a mock delay for now
/// so the UI is fully testable before backend/Firebase project keys exist.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api) : super(const AuthState());

  final ApiService _api;

  Future<void> sendOtp(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    
    // Check whitelist for Shop Owners
    const allowedOwners = [
      '8956824842',
      '8805707911',
      '8805779621',
      '9923185742',
      '9511689937',
    ];
    
    if (!allowedOwners.contains(cleanPhone)) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'authUnauthorizedOwner',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearError: true,
      phoneNumber: phoneNumber,
    );
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android only: automatic SMS resolution
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            state = state.copyWith(isLoading: false, step: AuthStep.roleSelect);
          } catch (e) {
            state = state.copyWith(isLoading: false, errorMessage: 'authOtpError');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print('verificationFailed Code: ${e.code}');
          print('verificationFailed Message: ${e.message}');
          print('verificationFailed StackTrace: ${e.stackTrace}');
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Firebase Error: ${e.message}',
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          state = state.copyWith(
            isLoading: false,
            step: AuthStep.otpVerify,
            verificationId: verificationId,
            resendCooldownSeconds: 30,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout
        },
      );
    } catch (e, stackTrace) {
      print('sendOtp Catch: $e');
      print('sendOtp StackTrace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (otp.length != 6) {
        throw Exception('invalid');
      }
      final verificationId = state.verificationId;
      if (verificationId == null) throw Exception('missing_verification_id');

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Check backend: if user already has a role, skip role-select and go
      // straight to done so returning users don't have to re-pick their role.
      try {
        final existing = await _api.getUserByPhone(state.phoneNumber);
        if (existing != null) {
          final role = UserRoleX.fromApi(existing['role'] as String?);
          if (role != null) {
            final userId = existing['id'] as String;

            // For owners: check whether a shop already exists so the
            // navigation listener can route directly to the dashboard
            // instead of always landing on shop-setup (which caused a
            // flash / re-setup prompt on every new device install).
            String? shopId, shopName, shopCode;
            if (role == UserRole.owner) {
              try {
                final shop = await _api.getShopByOwner(userId);
                if (shop != null) {
                  shopId = shop['id'] as String?;
                  shopName = shop['shop_name'] as String?;
                  shopCode = shop['shop_code'] as String?;
                }
              } catch (_) {
                // Shop lookup failed — fall through; shop-setup screen
                // has its own guard and will redirect if the shop exists.
              }
            }

            state = state.copyWith(
              isLoading: false,
              role: role,
              name: existing['name'] as String?,
              userId: userId,
              shopId: shopId,
              shopName: shopName,
              shopCode: shopCode,
              step: AuthStep.done,
            );
            return;
          }
        }
      } catch (_) {
        // If the backend lookup fails (new user / network blip),
        // fall through to role-select so the user can still register.
      }

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
      final user = await _api.upsertUser(
        phone: state.phoneNumber,
        role: role.apiValue,
        name: name,
      );
      final userId = user['id'] as String;

      // Safety: if an owner somehow already has a shop (e.g. they went
      // through role-select on a second device after their first device
      // created the shop without persisting the session properly), fetch
      // it so navigation goes straight to the dashboard.
      String? shopId, shopName, shopCode;
      if (role == UserRole.owner) {
        try {
          final shop = await _api.getShopByOwner(userId);
          if (shop != null) {
            shopId = shop['id'] as String?;
            shopName = shop['shop_name'] as String?;
            shopCode = shop['shop_code'] as String?;
          }
        } catch (_) {
          // Shop lookup failed — shop-setup screen's guard will handle it.
        }
      }

      state = state.copyWith(
        isLoading: false,
        role: role,
        name: name,
        userId: userId,
        shopId: shopId,
        shopName: shopName,
        shopCode: shopCode,
        step: AuthStep.done,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: errorKeyFor(e));
    }
  }

  Future<Map<String, dynamic>> upsertGuestUser({required String name, required String phone}) async {
    return await _api.upsertUser(
      phone: phone,
      role: UserRole.customer.apiValue,
      name: name,
    );
  }
}

final _apiServiceProvider = Provider((ref) => ApiService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(_apiServiceProvider)),
);

