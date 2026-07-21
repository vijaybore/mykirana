import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/product_models.dart';
import '../../../providers/session_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../cart/screens/cart_screen.dart';
import '../providers/product_provider.dart';

/// Customer's product browsing screen — category tabs across the top,
/// search below, then a scrollable product grid. Tapping "Add" adds one
/// unit to the cart; once something's in the cart a bottom bar shows
/// the running total and a way into the cart screen.
class CustomerBrowseScreen extends ConsumerStatefulWidget {
  const CustomerBrowseScreen({super.key});

  @override
  ConsumerState<CustomerBrowseScreen> createState() => _CustomerBrowseScreenState();
}

class _CustomerBrowseScreenState extends ConsumerState<CustomerBrowseScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final shopId = ref.watch(sessionProvider).shopId ?? '';
    final categoriesAsync = ref.watch(categoriesProvider(shopId));
    final productsAsync = ref.watch(browseProductsProvider(shopId));
    final filters = ref.watch(browseFiltersProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final cartTotal = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('browseTitle')),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                ),
              ),
              if (cartCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      '$cartCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.sm,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) =>
                  ref.read(browseFiltersProvider.notifier).setSearch(v),
              decoration: InputDecoration(
                hintText: t.t('browseSearchHint'),
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
          ),
          categoriesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (categories) => SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
                children: [
                  _CategoryTab(
                    label: t.t('browseAllCategory'),
                    selected: filters.categoryId == null,
                    onTap: () => ref.read(browseFiltersProvider.notifier).selectCategory(null),
                  ),
                  ...categories.map(
                    (c) => _CategoryTab(
                      label: c.name,
                      selected: filters.categoryId == c.id,
                      onTap: () =>
                          ref.read(browseFiltersProvider.notifier).selectCategory(c.id),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: productsAsync.when(
              loading: () => _LoadingGrid(),
              error: (err, st) => _ErrorState(
                onRetry: () => ref.invalidate(browseProductsProvider(shopId)),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return _EmptyState(message: t.t('browseEmpty'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    0,
                    AppSpacing.screenPadding,
                    AppSpacing.xxxl,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, i) => _ProductCard(product: products[i]),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: cartCount == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$cartCount ${t.t('navProducts')}'),
                      Text('₹${cartTotal.toStringAsFixed(0)}  •  ${t.t('cartCheckout')}'),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryLight,
        labelStyle: TextStyle(
          color: selected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final qty = ref.watch(cartProvider.select(
      (lines) => lines.where((l) => l.product.id == product.id).isEmpty
          ? 0
          : lines.firstWhere((l) => l.product.id == product.id).quantity,
    ));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
              child: Container(
                width: double.infinity,
                color: AppColors.background,
                child: (product.imageUrl == null || product.imageUrl!.isEmpty)
                    ? const Icon(Icons.inventory_2_outlined,
                        color: AppColors.textMuted, size: 32)
                    : Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.inventory_2_outlined, color: AppColors.textMuted),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: AppTextStyles.productName, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('₹${product.price.toStringAsFixed(0)} / ${product.unit}',
                    style: AppTextStyles.bodySmall),
                const SizedBox(height: AppSpacing.sm),
                qty == 0
                    ? SizedBox(
                        width: double.infinity,
                        height: 34,
                        child: OutlinedButton(
                          onPressed: () => ref.read(cartProvider.notifier).add(product),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                          child: Text(t.t('browseAddToCart'),
                              style: const TextStyle(color: AppColors.primary, fontSize: 13)),
                        ),
                      )
                    : Container(
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 34),
                              icon: const Icon(Icons.remove, color: Colors.white, size: 16),
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .setQuantity(product.id, qty - 1),
                            ),
                            Text('$qty',
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w700)),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 34),
                              icon: const Icon(Icons.add, color: Colors.white, size: 16),
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .setQuantity(product.id, qty + 1),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.skeletonBase,
      highlightColor: AppColors.skeletonHighlight,
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.78,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(t.t('errorGeneric'), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: Text(t.t('commonRetry'))),
          ],
        ),
      ),
    );
  }
}
