import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../providers/auth_provider.dart' show errorKeyFor;

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
    String? contactPhone,
    String? shopImageUrl,
    String? upiQrImageUrl,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final shop = await _api.createShop(
        ownerId: ownerId,
        shopName: shopName,
        address: address,
        businessUpiId: businessUpiId,
        contactPhone: contactPhone,
        shopImageUrl: shopImageUrl,
        upiQrImageUrl: upiQrImageUrl,
      );
      state = state.copyWith(isLoading: false);
      return shop;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: errorKeyFor(e));
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateShop({
    required String shopId,
    String? shopName,
    String? address,
    String? businessUpiId,
    String? contactPhone,
    String? shopImageUrl,
    String? upiQrImageUrl,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final shop = await _api.updateShop(
        id: shopId,
        shopName: shopName,
        address: address,
        businessUpiId: businessUpiId,
        contactPhone: contactPhone,
        shopImageUrl: shopImageUrl,
        upiQrImageUrl: upiQrImageUrl,
      );
      state = state.copyWith(isLoading: false);
      return shop;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: errorKeyFor(e));
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
      state = state.copyWith(isLoading: false, errorMessage: errorKeyFor(e));
      return null;
    }
  }
}

final shopActionProvider =
    StateNotifierProvider<ShopActionNotifier, ShopActionState>(
  (ref) => ShopActionNotifier(ref.watch(_apiServiceProvider)),
);

/// Full shop record (address, UPI, contact, images — everything the
/// slim session state doesn't carry) looked up by code. Shared by
/// checkout (needs the UPI ID) and the shop-edit screen (needs
/// everything, to pre-fill the form).
final shopDetailsProvider =
    FutureProvider.family.autoDispose<Map<String, dynamic>?, String>((ref, shopCode) async {
  if (shopCode.isEmpty) return null;
  final api = ref.watch(_apiServiceProvider);
  return api.getShopByCode(shopCode);
});

