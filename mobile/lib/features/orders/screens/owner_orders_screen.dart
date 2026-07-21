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

/// Owner's incoming-orders queue — newest first, with a one-tap action
/// to move each order to the next stage (placed -> ready -> completed).
class OwnerOrdersScreen extends ConsumerWidget {
  const OwnerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final shopId = ref.watch(sessionProvider).shopId ?? '';
    final ordersAsync = ref.watch(shopOrdersProvider(shopId));

    return Scaffold(
      appBar: AppBar(title: Text(t.t('ordersTitle'))),
      body: RefreshIndicator(
        onRefresh: () => ref.read(shopOrdersProvider(shopId).notifier).refresh(),
        child: ordersAsync.when(
          loading: () => _LoadingList(),
          error: (err, st) => _ErrorState(
            onRetry: () => ref.read(shopOrdersProvider(shopId).notifier).refresh(),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return _EmptyState(message: t.t('ordersEmptyOwner'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: orders.length,
              itemBuilder: (context, i) =>
                  _OwnerOrderCard(order: orders[i], shopId: shopId),
            );
          },
        ),
      ),
    );
  }
}

class _OwnerOrderCard extends ConsumerWidget {
  const _OwnerOrderCard({required this.order, required this.shopId});
  final Order order;
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Text('#${order.id.substring(0, 8).toUpperCase()}',
                  style: AppTextStyles.label),
              _PaymentBadge(order: order, t: t),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.t('orderItemsCount', params: {'count': '${order.itemCount}'}),
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 2),
          Text('₹${order.total.toStringAsFixed(0)}', style: AppTextStyles.priceMedium),
          const SizedBox(height: AppSpacing.md),
          OrderStatusStepper(status: order.status),
          if (order.status != OrderStatus.completed) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  final next = order.status == OrderStatus.placed
                      ? OrderStatus.ready
                      : OrderStatus.completed;
                  ref.read(shopOrdersProvider(shopId).notifier).updateStatus(order.id, next);
                },
                child: Text(
                  order.status == OrderStatus.placed
                      ? t.t('orderMarkReady')
                      : t.t('orderMarkCompleted'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.order, required this.t});
  final Order order;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    final label = switch (order.paymentMode) {
      PaymentMode.cash => t.t('orderPaymentCash'),
      PaymentMode.upi => t.t('orderPaymentUpi'),
      PaymentMode.udhari => t.t('orderPaymentUdhari'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentDark),
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
          height: 130,
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
