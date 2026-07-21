import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/order_models.dart';
import '../../../models/product_models.dart';

/// In-memory cart — deliberately not persisted to disk or synced to the
/// backend until checkout. A cart is disposable browsing state, not data
/// that needs to survive an app kill; the moment it matters (an actual
/// order) it becomes a real synced record via placeOrder().
class CartNotifier extends StateNotifier<List<CartLine>> {
  CartNotifier() : super(const []);

  void add(Product product, {int quantity = 1}) {
    final idx = state.indexWhere((l) => l.product.id == product.id);
    if (idx == -1) {
      state = [...state, CartLine(product: product, quantity: quantity)];
    } else {
      final updated = [...state];
      updated[idx] = updated[idx].copyWith(
        quantity: updated[idx].quantity + quantity,
      );
      state = updated;
    }
  }

  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    state = [
      for (final line in state)
        if (line.product.id == productId)
          line.copyWith(quantity: quantity)
        else
          line,
    ];
  }

  void remove(String productId) {
    state = state.where((l) => l.product.id != productId).toList();
  }

  void clear() => state = const [];

  int quantityFor(String productId) {
    final line = state.where((l) => l.product.id == productId);
    return line.isEmpty ? 0 : line.first.quantity;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartLine>>(
  (ref) => CartNotifier(),
);

final cartTotalProvider = Provider<double>((ref) {
  final lines = ref.watch(cartProvider);
  return lines.fold(0.0, (sum, l) => sum + l.lineTotal);
});

final cartItemCountProvider = Provider<int>((ref) {
  final lines = ref.watch(cartProvider);
  return lines.fold(0, (sum, l) => sum + l.quantity);
});
