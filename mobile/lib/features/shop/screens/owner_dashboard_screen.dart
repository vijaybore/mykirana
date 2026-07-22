import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../../../providers/session_provider.dart';
import '../../../models/order_models.dart';
import '../../orders/providers/order_provider.dart';
import '../../orders/screens/owner_orders_screen.dart';
import '../../products/screens/owner_product_list_screen.dart';
import '../../udhari/providers/udhari_provider.dart';
import '../../udhari/screens/udhari_customer_list_screen.dart';
import '../../shared/widgets/switch_account_action.dart';
import 'shop_edit_screen.dart';
import 'shop_qr_screen.dart';

/// Owner's home base — shop code at a glance, then quick access to the
/// four things an owner actually does day to day: see new orders,
/// manage the catalog, check who owes udhari, and share the shop QR.
class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final shopId = session.shopId ?? '';

    final ordersAsync = ref.watch(shopOrdersProvider(shopId));
    final newOrders = ordersAsync.maybeWhen(
      data: (orders) => orders.where((o) => o.status == OrderStatus.placed).length,
      orElse: () => 0,
    );

    final udhariAsync = ref.watch(udhariCustomerListProvider(shopId));
    final totalOwed = udhariAsync.maybeWhen(
      data: (customers) =>
          customers.fold<double>(0, (sum, c) => sum + (c.balance > 0 ? c.balance : 0)),
      orElse: () => 0.0,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(t.t('dashboardWelcome')),
        actions: [
          const SwitchAccountAction(),
          IconButton(
            icon: const Icon(Icons.qr_code_rounded),
            tooltip: t.t('shopQrTitle'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ShopQrScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(session.shopName ?? '', style: AppTextStyles.h3),
                        const SizedBox(height: 4),
                        Text(t.t('dashboardShopCode'), style: AppTextStyles.caption),
                        Text(
                          session.shopCode ?? '',
                          style: AppTextStyles.h2.copyWith(letterSpacing: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 36),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: t.t('dashboardIncomingOrders'),
                    value: '$newOrders',
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCard(
                    label: t.t('udhariTotalOwed'),
                    value: '₹${totalOwed.toStringAsFixed(0)}',
                    color: AppColors.udhariOwing,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            _NavCard(
              icon: Icons.receipt_long_rounded,
              title: t.t('dashboardViewOrders'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OwnerOrdersScreen()),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NavCard(
              icon: Icons.inventory_2_outlined,
              title: t.t('dashboardManageProducts'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OwnerProductListScreen()),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NavCard(
              icon: Icons.menu_book_rounded,
              title: t.t('dashboardViewUdhari'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UdhariCustomerListScreen()),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NavCard(
              icon: Icons.qr_code_rounded,
              title: t.t('dashboardViewShopQr'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShopQrScreen()),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _NavCard(
              icon: Icons.storefront_outlined,
              title: t.t('dashboardEditShop'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ShopEditScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTextStyles.h2.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(title,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
