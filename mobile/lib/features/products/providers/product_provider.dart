import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_models.dart';
import '../../../providers/auth_provider.dart' show errorKeyFor;
import '../../../services/api_service.dart';

final _apiServiceProvider = Provider((ref) => ApiService());

/// Categories for a shop — shared by the owner's product form and the
/// customer's browse-by-category tabs, so both stay in sync.
final categoriesProvider =
    FutureProvider.family<List<Category>, String>((ref, shopId) async {
  if (shopId.isEmpty) return [];
  final api = ref.watch(_apiServiceProvider);
  final rows = await api.getCategories(shopId);
  return rows.map(Category.fromJson).toList();
});

/// Owner's full product catalog (includes out-of-stock items, since the
/// owner needs to see and toggle them). Re-fetch with `.refresh()` after
/// any add/edit/delete so the list stays current.
class ProductListNotifier
    extends StateNotifier<AsyncValue<List<Product>>> {
  ProductListNotifier(this._api, this.shopId) : super(const AsyncValue.loading()) {
    refresh();
  }

  final ApiService _api;
  final String shopId;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final rows = await _api.getProducts(shopId);
      state = AsyncValue.data(rows.map(Product.fromJson).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> toggleStock(Product product) async {
    try {
      await _api.setProductStock(id: product.id, inStock: !product.inStock);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    try {
      await _api.deleteProduct(productId);
      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final productListProvider = StateNotifierProvider.family<ProductListNotifier,
    AsyncValue<List<Product>>, String>(
  (ref, shopId) => ProductListNotifier(ref.watch(_apiServiceProvider), shopId),
);

/// Handles the add/edit product form submission (create category on the
/// fly too, since the owner shouldn't have to leave the form to set one up).
class ProductFormState {
  final bool isLoading;
  final String? errorMessage;
  const ProductFormState({this.isLoading = false, this.errorMessage});

  ProductFormState copyWith({bool? isLoading, String? errorMessage}) =>
      ProductFormState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  ProductFormNotifier(this._api) : super(const ProductFormState());

  final ApiService _api;

  Future<Category?> createCategory({
    required String shopId,
    required String name,
  }) async {
    try {
      final json = await _api.createCategory(shopId: shopId, name: name);
      return Category.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveProduct({
    String? existingId,
    required String shopId,
    String? categoryId,
    required String name,
    required double price,
    required String unit,
    String? imageUrl,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (existingId == null) {
        await _api.createProduct(
          shopId: shopId,
          categoryId: categoryId,
          name: name,
          price: price,
          unit: unit,
          imageUrl: imageUrl,
        );
      } else {
        await _api.updateProduct(
          id: existingId,
          categoryId: categoryId,
          name: name,
          price: price,
          unit: unit,
          imageUrl: imageUrl,
        );
      }
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: errorKeyFor(e));
      return false;
    }
  }
}

final productFormProvider =
    StateNotifierProvider<ProductFormNotifier, ProductFormState>(
  (ref) => ProductFormNotifier(ref.watch(_apiServiceProvider)),
);

/// Customer browse filters — category tab + search text. Kept as simple
/// provider state rather than folded into the query so switching tabs or
/// typing doesn't need to re-create the FutureProvider's family key type.
class BrowseFilters {
  final String? categoryId;
  final String search;
  const BrowseFilters({this.categoryId, this.search = ''});

  BrowseFilters copyWith({String? categoryId, bool clearCategory = false, String? search}) {
    return BrowseFilters(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      search: search ?? this.search,
    );
  }
}

class BrowseFiltersNotifier extends StateNotifier<BrowseFilters> {
  BrowseFiltersNotifier() : super(const BrowseFilters());

  void selectCategory(String? categoryId) {
    state = categoryId == null
        ? state.copyWith(clearCategory: true)
        : state.copyWith(categoryId: categoryId);
  }

  void setSearch(String value) => state = state.copyWith(search: value);
}

final browseFiltersProvider =
    StateNotifierProvider<BrowseFiltersNotifier, BrowseFilters>(
  (ref) => BrowseFiltersNotifier(),
);

/// Customer-facing product list — always in-stock-only, filtered by the
/// selected category and search text from [browseFiltersProvider].
final browseProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, shopId) async {
  if (shopId.isEmpty) return [];
  final filters = ref.watch(browseFiltersProvider);
  final api = ref.watch(_apiServiceProvider);
  final rows = await api.getProducts(
    shopId,
    categoryId: filters.categoryId,
    search: filters.search.isEmpty ? null : filters.search,
    inStockOnly: true,
  );
  return rows.map(Product.fromJson).toList();
});
