import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/order_models.dart';
import '../../../providers/auth_provider.dart' show errorKeyFor;
import '../../../services/api_service.dart';

final _apiServiceProvider = Provider((ref) => ApiService());

/// Owner's incoming orders for their shop, newest first.
class ShopOrdersNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  ShopOrdersNotifier(this._api, this.shopId) : super(const AsyncValue.loading()) {
    refresh();
  }

  final ApiService _api;
  final String shopId;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final rows = await _api.getShopOrders(shopId);
      state = AsyncValue.data(rows.map(Order.fromJson).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Optimistically updates the order's status locally, then confirms
  /// with the backend — so tapping "Mark Ready" feels instant instead
  /// of waiting a full round trip before the UI reflects it.
  Future<bool> updateStatus(String orderId, OrderStatus status) async {
    final previous = state;
    state = state.whenData(
      (orders) => [
        for (final o in orders)
          if (o.id == orderId)
            Order(
              id: o.id,
              shopId: o.shopId,
              customerId: o.customerId,
              items: o.items,
              paymentMode: o.paymentMode,
              paymentStatus: o.paymentStatus,
              fulfillmentType: o.fulfillmentType,
              status: status,
              createdAt: o.createdAt,
            )
          else
            o,
      ],
    );
    try {
      await _api.updateOrderStatus(id: orderId, status: status.apiValue);
      return true;
    } catch (_) {
      state = previous; // revert on failure
      return false;
    }
  }
}

final shopOrdersProvider = StateNotifierProvider.family<ShopOrdersNotifier,
    AsyncValue<List<Order>>, String>(
  (ref, shopId) => ShopOrdersNotifier(ref.watch(_apiServiceProvider), shopId),
);

/// Customer's own order history for their linked shop.
class CustomerOrdersNotifier extends StateNotifier<AsyncValue<List<Order>>> {
  CustomerOrdersNotifier(this._api, this.customerId, this.shopId)
      : super(const AsyncValue.loading()) {
    refresh();
  }

  final ApiService _api;
  final String customerId;
  final String shopId;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final rows = await _api.getCustomerOrders(customerId, shopId: shopId);
      state = AsyncValue.data(rows.map(Order.fromJson).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Lets a customer cancel their own order before the shop marks it
  /// ready. The backend independently enforces that a completed order
  /// can't be cancelled and reverses any udhari credit — this is just
  /// the optimistic-update mirror of that on the customer's list.
  Future<bool> cancelOrder(String orderId) async {
    final previous = state;
    state = state.whenData(
      (orders) => [
        for (final o in orders)
          if (o.id == orderId)
            Order(
              id: o.id,
              shopId: o.shopId,
              customerId: o.customerId,
              items: o.items,
              paymentMode: o.paymentMode,
              paymentStatus: o.paymentStatus,
              fulfillmentType: o.fulfillmentType,
              status: OrderStatus.cancelled,
              createdAt: o.createdAt,
            )
          else
            o,
      ],
    );
    try {
      await _api.updateOrderStatus(id: orderId, status: OrderStatus.cancelled.apiValue);
      return true;
    } catch (_) {
      state = previous;
      return false;
    }
  }
}

final customerOrdersProvider = StateNotifierProvider.family<
    CustomerOrdersNotifier,
    AsyncValue<List<Order>>,
    ({String customerId, String shopId})>(
  (ref, args) => CustomerOrdersNotifier(
    ref.watch(_apiServiceProvider),
    args.customerId,
    args.shopId,
  ),
);

/// Handles the checkout submission itself (placing the order).
class CheckoutState {
  final bool isLoading;
  final String? errorMessage;
  const CheckoutState({this.isLoading = false, this.errorMessage});

  CheckoutState copyWith({bool? isLoading, String? errorMessage}) =>
      CheckoutState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier(this._api) : super(const CheckoutState());

  final ApiService _api;

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String message) {
    state = state.copyWith(isLoading: false, errorMessage: message);
  }

  Future<Order?> placeOrder({
    required String shopId,
    required String customerId,
    required List<Map<String, dynamic>> items,
    required PaymentMode paymentMode,
    FulfillmentType fulfillmentType = FulfillmentType.pickup,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final json = await _api.placeOrder(
        shopId: shopId,
        customerId: customerId,
        items: items,
        paymentMode: paymentMode.apiValue,
        fulfillmentType: fulfillmentType.apiValue,
      );
      state = state.copyWith(isLoading: false);
      return Order.fromJson(json);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: errorKeyFor(e));
      return null;
    }
  }
}

 
final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>(
  (ref) => CheckoutNotifier(ref.watch(_apiServiceProvider)),
);
