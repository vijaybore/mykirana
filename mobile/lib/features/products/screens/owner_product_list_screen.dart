import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/product_models.dart';
import '../../../providers/session_provider.dart';
import '../providers/product_provider.dart';
import 'product_edit_sheet.dart';

/// Owner's product catalog — list with stock toggle, edit, delete, and
/// a FAB to add new products. Out-of-stock items stay visible here
/// (unlike the customer's browse screen) since the owner needs to
/// re-enable them.
class OwnerProductListScreen extends ConsumerWidget {
  const OwnerProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final shopId = ref.watch(sessionProvider).shopId ?? '';
    final productsAsync = ref.watch(productListProvider(shopId));

    return Scaffold(
      appBar: AppBar(title: Text(t.t('productsTitle'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, shopId: shopId),
        icon: const Icon(Icons.add_rounded),
        label: Text(t.t('productsAddNew')),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(productListProvider(shopId).notifier).refresh(),
        child: productsAsync.when(
          loading: () => _LoadingList(),
          error: (err, st) => _ErrorState(
            onRetry: () => ref.read(productListProvider(shopId).notifier).refresh(),
          ),
          data: (products) {
            if (products.isEmpty) {
              return _EmptyState(message: t.t('productsEmpty'));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.screenPadding,
                AppSpacing.screenPadding,
                AppSpacing.xxxl,
              ),
              itemCount: products.length,
              itemBuilder: (context, i) => _ProductRow(
                product: products[i],
                shopId: shopId,
              ),
            );
          },
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, {required String shopId, Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductEditSheet(shopId: shopId, product: product),
    );
  }
}

class _ProductRow extends ConsumerWidget {
  const _ProductRow({required this.product, required this.shopId});

  final Product product;
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _Thumbnail(imageUrl: product.imageUrl),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, style: AppTextStyles.productName),
                const SizedBox(height: 2),
                Text(
                  '₹${product.price.toStringAsFixed(0)} / ${product.unit}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  product.inStock ? t.t('productInStock') : t.t('productOutOfStock'),
                  style: AppTextStyles.caption.copyWith(
                    color: product.inStock ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: product.inStock,
                activeThumbColor: AppColors.primary,
                onChanged: (_) =>
                    ref.read(productListProvider(shopId).notifier).toggleStock(product),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: AppColors.textSecondary,
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          ProductEditSheet(shopId: shopId, product: product),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: AppColors.danger,
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.t('productDeleteConfirm')),
        content: Text(t.t('productDeleteConfirmBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.t('commonCancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(productListProvider(shopId).notifier).deleteProduct(product.id);
            },
            child: Text(t.t('commonDelete'),
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 52,
        height: 52,
        color: AppColors.background,
        child: (imageUrl == null || imageUrl!.isEmpty)
            ? const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted)
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted),
              ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.skeletonBase,
      highlightColor: AppColors.skeletonHighlight,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 76,
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
            const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.textMuted),
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
