import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/udhari_models.dart';
import '../../../providers/session_provider.dart';
import '../providers/udhari_provider.dart';
import 'udhari_customer_detail_screen.dart';

/// Owner's "उधार यादी" — every customer who has a udhari relationship
/// with this shop, sorted highest balance first, so the owner always
/// sees who owes the most right at the top.
class UdhariCustomerListScreen extends ConsumerWidget {
  const UdhariCustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final shopId = ref.watch(sessionProvider).shopId ?? '';
    final customersAsync = ref.watch(udhariCustomerListProvider(shopId));

    return Scaffold(
      appBar: AppBar(title: Text(t.t('udhariListTitle'))),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(udhariCustomerListProvider(shopId).notifier).refresh(),
        child: customersAsync.when(
          loading: () => _LoadingList(),
          error: (err, st) => _ErrorState(
            onRetry: () =>
                ref.read(udhariCustomerListProvider(shopId).notifier).refresh(),
          ),
          data: (customers) {
            if (customers.isEmpty) {
              return _EmptyState(message: t.t('udhariListEmpty'));
            }

            final totalOwed = customers.fold<double>(
              0,
              (sum, c) => sum + (c.balance > 0 ? c.balance : 0),
            );

            return ListView(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.udhariOwingBg,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.t('udhariTotalOwed'), style: AppTextStyles.label
                          .copyWith(color: AppColors.udhariOwing)),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        '₹${totalOwed.toStringAsFixed(0)}',
                        style: AppTextStyles.balanceAmount
                            .copyWith(color: AppColors.udhariOwing),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                ...customers.map(
                  (c) => _CustomerCard(customer: c, shopId: shopId),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.shopId});

  final UdhariCustomerSummary customer;
  final String shopId;

  @override
  Widget build(BuildContext context) {
    final isClear = customer.balance <= 0;
    final color = isClear ? AppColors.udhariClear : AppColors.udhariOwing;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UdhariCustomerDetailScreen(
                shopId: shopId,
                customerId: customer.customerId,
                customerName: customer.displayName,
              ),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  customer.displayName.isNotEmpty
                      ? customer.displayName[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.displayName, style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600)),
                    Text(customer.phone, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Text(
                isClear ? '₹0' : '₹${customer.balance.toStringAsFixed(0)}',
                style: AppTextStyles.priceMedium.copyWith(color: color),
              ),
              SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ],
          ),
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
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 68,
          margin: EdgeInsets.only(bottom: AppSpacing.sm),
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
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_rounded,
                size: 48, color: AppColors.textMuted),
            SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
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
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 48, color: AppColors.textMuted),
            SizedBox(height: AppSpacing.md),
            Text(t.t('errorGeneric'), textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: Text(t.t('commonRetry'))),
          ],
        ),
      ),
    );
  }
}

