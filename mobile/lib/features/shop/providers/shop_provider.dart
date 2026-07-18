import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_service.dart';

final _apiServiceProvider = Provider((ref) => ApiService());

class ShopActionState {
  final bool isLoading;
  final String? errorMessage;

  const ShopActionState({this.isLoading = false, this.errorMessage});

  ShopActionState copyWith({bool? isLoading, String? errorMessage}) {
    return ShopActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Handles both sides of "getting a shop attached to this session":
/// an owner creating their shop, or a customer linking to one via
/// code/QR. Both end the same way — session.setLinkedShop(...) —
/// which is what makes the shop "always there" on next app open.
class ShopActionNotifier extends StateNotifier<ShopActionState> {
  ShopActionNotifier(this._api) : super(const ShopActionState());

  final ApiService _api;

  Future<Map<String, dynamic>?> createShop({
    required String ownerId,
    required String shopName,
    String? address,
    String? businessUpiId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final shop = await _api.createShop(
        ownerId: ownerId,
        shopName: shopName,
        address: address,
        businessUpiId: businessUpiId,
      );
      state = state.copyWith(isLoading: false);
      return shop;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'errorGeneric');
      return null;
    }
  }

  /// Looks up a shop by code, then links the customer to it.
  /// Returns the shop record on success, or null (with errorMessage
  /// set to the right key) if the code doesn't exist or the request
  /// failed for any other reason.
  Future<Map<String, dynamic>?> linkToShopByCode({
    required String customerId,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final shop = await _api.getShopByCode(code.trim().toUpperCase());
      if (shop == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'shopLinkInvalidCode',
        );
        return null;
      }

      await _api.linkCustomerToShop(
        customerId: customerId,
        shopId: shop['id'] as String,
      );

      state = state.copyWith(isLoading: false);
      return shop;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'errorGeneric');
      return null;
    }
  }
}

final shopActionProvider =
    StateNotifierProvider<ShopActionNotifier, ShopActionState>(
  (ref) => ShopActionNotifier(ref.watch(_apiServiceProvider)),
);

