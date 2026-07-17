import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Minimal session context: which user is logged in, and which shop
/// they're currently acting on (their own shop if owner, or the shop
/// they've linked to if customer).
///
/// TODO: populate userId from Firebase Auth UID / backend user record
/// once selectRole() in auth_provider persists to POST /users.
/// TODO: populate shopId from the owner's shop record, or from the
/// customer's CustomerShopLink once the shop-linking screen is built.
class SessionState {
  final String? userId;
  final String? shopId;

  const SessionState({this.userId, this.shopId});

  SessionState copyWith({String? userId, String? shopId}) {
    return SessionState(
      userId: userId ?? this.userId,
      shopId: shopId ?? this.shopId,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(const SessionState());

  void setUser(String userId) => state = state.copyWith(userId: userId);
  void setShop(String shopId) => state = state.copyWith(shopId: shopId);
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>(
  (ref) => SessionNotifier(),
);

