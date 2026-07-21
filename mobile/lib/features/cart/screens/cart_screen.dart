import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../providers/cart_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final lines = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.t('cartTitle'))),
      body: lines.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_cart_outlined,
                        size: 48, color: AppColors.textMuted),
                    const SizedBox(height: AppSpacing.md),
                    Text(t.t('cartEmpty'), style: AppTextStyles.h3),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      t.t('cartEmptySubtitle'),
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: lines.length,
              itemBuilder: (context, i) {
                final line = lines[i];
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.product.name, style: AppTextStyles.productName),
                            const SizedBox(height: 2),
                            Text(
                              '₹${line.product.price.toStringAsFixed(0)} / ${line.product.unit}',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppColors.primary,
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .setQuantity(line.product.id, line.quantity - 1),
                          ),
                          Text('${line.quantity}', style: AppTextStyles.bodyLarge),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: AppColors.primary,
                            onPressed: () => ref
                                .read(cartProvider.notifier)
                                .setQuantity(line.product.id, line.quantity + 1),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(
                          '₹${line.lineTotal.toStringAsFixed(0)}',
                          textAlign: TextAlign.end,
                          style: AppTextStyles.priceMedium,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: lines.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t.t('cartItemTotal'), style: AppTextStyles.label),
                        Text('₹${total.toStringAsFixed(0)}', style: AppTextStyles.priceLarge),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                        ),
                        child: Text(t.t('cartCheckout')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
