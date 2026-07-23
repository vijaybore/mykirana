import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/screen_util.dart';
import '../../../localization/app_localizations.dart';
import '../../../providers/session_provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../cart/screens/cart_screen.dart';
import '../../orders/screens/customer_orders_screen.dart';
import '../../products/screens/customer_browse_screen.dart';
import '../../shared/widgets/switch_account_action.dart';
import '../../udhari/providers/udhari_provider.dart';
import '../../udhari/screens/my_udhari_screen.dart';

/// Customer's home base — their linked shop at a glance, plus quick
/// access to browsing products, their cart, udhari balance, and orders.
class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final shopId = session.shopId ?? '';
    final customerId = session.userId ?? '';

    final args = (shopId: shopId, customerId: customerId);
    ref.watch(udhariHistoryProvider(args)); // keeps it loaded/refreshed
    final balance = ref.watch(udhariHistoryProvider(args).notifier).balance;

    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          t.t('customerHomeWelcomeTo', params: {'shopName': session.shopName ?? ''}),
        ),
        actions: const [SwitchAccountAction()],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.lg),
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
                        Text(t.t('customerHomeShopInfo'), style: AppTextStyles.caption),
                        const SizedBox(height: 2),
                        Text(session.shopName ?? '', style: AppTextStyles.h3),
                      ],
                    ),
                  ),
                  const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 32),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.lg),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: balance > 0 ? AppColors.udhariOwingBg : AppColors.udhariClearBg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    balance > 0 ? t.t('udhariMyBalanceOwing') : t.t('udhariMyBalanceClear'),
                    style: AppTextStyles.label.copyWith(
                      color: balance > 0 ? AppColors.udhariOwing : AppColors.udhariClear,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${balance.toStringAsFixed(0)}',
                    style: AppTextStyles.balanceAmount.copyWith(
                      color: balance > 0 ? AppColors.udhariOwing : AppColors.udhariClear,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xl),

            _NavCard(
              icon: Icons.storefront_outlined,
              title: t.t('customerHomeBrowse'),
              badge: cartCount > 0 ? '$cartCount' : null,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomerBrowseScreen()),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            _NavCard(
              icon: Icons.shopping_cart_outlined,
              title: t.t('cartTitle'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            _NavCard(
              icon: Icons.menu_book_rounded,
              title: t.t('customerHomeMyUdhari'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyUdhariScreen()),
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            _NavCard(
              icon: Icons.receipt_long_rounded,
              title: t.t('customerHomeMyOrders'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CustomerOrdersScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({required this.icon, required this.title, required this.onTap, this.badge});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: ScreenUtil.dp(44),
              height: ScreenUtil.dp(44),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(title,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(badge!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              SizedBox(width: AppSpacing.sm),
            ],
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
