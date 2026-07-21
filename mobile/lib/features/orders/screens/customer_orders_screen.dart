import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/order_models.dart';
import '../../../providers/session_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_status_stepper.dart';

/// Customer's own order history — each card shows what was ordered, the
/// total, and a status stepper so they can see at a glance whether it's
/// still being prepared or ready for pickup.
class CustomerOrdersScreen extends ConsumerWidget {
  const CustomerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final args = (customerId: session.userId ?? '', shopId: session.shopId ?? '');
    final ordersAsync = ref.watch(customerOrdersProvider(args));

    return Scaffold(
      appBar: AppBar(title: Text(t.t('ordersTitle'))),
      body: RefreshIndicator(
        onRefresh: () => ref.read(customerOrdersProvider(args).notifier).refresh(),
        child: ordersAsync.when(
          loading: () => _LoadingList(),
          error: (err, st) => _ErrorState(
            onRetry: () => ref.read(customerOrdersProvider(args).notifier).refresh(),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return _EmptyState(message: t.t('ordersEmpty'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: orders.length,
              itemBuilder: (context, i) => _CustomerOrderCard(order: orders[i]),
            );
          },
        ),
      ),
    );
  }
}

class _CustomerOrderCard extends StatelessWidget {
  const _CustomerOrderCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${order.id.substring(0, 8).toUpperCase()}', style: AppTextStyles.label),
              Text('₹${order.total.toStringAsFixed(0)}', style: AppTextStyles.priceMedium),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            t.t('orderItemsCount', params: {'count': '${order.itemCount}'}),
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          OrderStatusStepper(status: order.status),
        ],
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
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
            const Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.textMuted),
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
