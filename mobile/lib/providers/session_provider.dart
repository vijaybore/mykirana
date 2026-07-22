import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart' show UserRole, UserRoleX;
import '../services/local_prefs_service.dart';

/// Current session context — who's logged in, what role they picked,
/// and (once set up / linked) which shop they're acting on.
///
/// Seeded at app startup from whatever was persisted locally (see
/// main.dart's bootstrap step), so a returning owner or a customer
/// who already linked to their shop lands straight back where they
/// left off instead of re-doing role selection / shop linking.
class SessionState {
  final String? userId;
  final UserRole? role;
  final String? shopId;
  final String? shopName;
  final String? shopCode;

  const SessionState({
    this.userId,
    this.role,
    this.shopId,
    this.shopName,
    this.shopCode,
  });

  bool get hasLinkedShop => shopId != null && shopId!.isNotEmpty;

  SessionState copyWith({
    String? userId,
    UserRole? role,
    String? shopId,
    String? shopName,
    String? shopCode,
  }) {
    return SessionState(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      shopCode: shopCode ?? this.shopCode,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier(this._prefs, SessionState initial) : super(initial);

  final LocalPrefsService _prefs;

  void setUser({required String userId, required UserRole role}) {
    state = state.copyWith(userId: userId, role: role);
    _prefs.saveUser(userId: userId, role: role.apiValue);
  }

  void setRole(UserRole role) {
    state = state.copyWith(role: role);
    _prefs.saveRole(role.apiValue);
  }

  /// Called once a shop is created (owner) or linked via code/QR
  /// (customer) — this is the "always there" memory the plan calls
  /// for, so the shop doesn't need re-linking on every app open.
  void setLinkedShop({
    required String shopId,
    required String shopName,
    required String shopCode,
  }) {
    state = state.copyWith(
      shopId: shopId,
      shopName: shopName,
      shopCode: shopCode,
    );
    _prefs.saveLinkedShop(shopId: shopId, shopName: shopName, shopCode: shopCode);
  }

  void clearLinkedShop() {
    state = SessionState(userId: state.userId, role: state.role);
    _prefs.clearLinkedShop();
  }

  void signOut() {
    state = const SessionState();
    _prefs.clearAll();
  }
}

final localPrefsProvider = Provider((ref) => LocalPrefsService());

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>(
  (ref) => SessionNotifier(ref.watch(localPrefsProvider), const SessionState()),
);

