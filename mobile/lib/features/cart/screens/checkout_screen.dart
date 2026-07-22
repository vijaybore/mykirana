import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/order_models.dart';
import '../../../providers/session_provider.dart';
import '../../orders/providers/order_provider.dart';
import '../../shop/providers/shop_provider.dart';
import '../providers/cart_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  PaymentMode _mode = PaymentMode.cash;
  FulfillmentType _fulfillmentType = FulfillmentType.pickup;
  Order? _placedOrder;

  Future<void> _confirmAndPlaceOrder() async {
    final t = AppLocalizations.of(context);
    final total = ref.read(cartTotalProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.t('checkoutConfirmTitle')),
        content: Text(
          t.t('checkoutConfirmBody', params: {'amount': total.toStringAsFixed(0)}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.t('commonCancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.t('checkoutPlaceOrder')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _placeOrder();
    }
  }

  Future<void> _placeOrder() async {
    final session = ref.read(sessionProvider);
    final lines = ref.read(cartProvider);
    if (session.userId == null || session.shopId == null || lines.isEmpty) return;

    final order = await ref.read(checkoutProvider.notifier).placeOrder(
          shopId: session.shopId!,
          customerId: session.userId!,
          items: lines.map((l) => l.toOrderItem()).toList(),
          paymentMode: _mode,
          fulfillmentType: _fulfillmentType,
        );

    if (order != null) {
      ref.read(cartProvider.notifier).clear();
      setState(() => _placedOrder = order);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (_placedOrder != null) {
      return _OrderPlacedView(order: _placedOrder!);
    }

    final lines = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final shopDetailsAsync = ref.watch(shopDetailsProvider(ref.watch(sessionProvider).shopCode ?? ''));

    return Scaffold(
      appBar: AppBar(title: Text(t.t('checkoutTitle'))),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.t('checkoutFulfillment'), style: AppTextStyles.h3),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _FulfillmentOption(
                            icon: Icons.storefront_outlined,
                            title: t.t('checkoutPickup'),
                            selected: _fulfillmentType == FulfillmentType.pickup,
                            onTap: () =>
                                setState(() => _fulfillmentType = FulfillmentType.pickup),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _FulfillmentOption(
                            icon: Icons.two_wheeler_outlined,
                            title: t.t('checkoutDelivery'),
                            selected: _fulfillmentType == FulfillmentType.delivery,
                            onTap: () =>
                                setState(() => _fulfillmentType = FulfillmentType.delivery),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Text(t.t('checkoutPaymentMode'), style: AppTextStyles.h3),
                    const SizedBox(height: AppSpacing.md),

                    _PaymentOption(
                      icon: Icons.payments_outlined,
                      title: t.t('checkoutCash'),
                      subtitle: t.t('checkoutCashDesc'),
                      selected: _mode == PaymentMode.cash,
                      onTap: () => setState(() => _mode = PaymentMode.cash),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PaymentOption(
                      icon: Icons.qr_code_rounded,
                      title: t.t('checkoutUpi'),
                      subtitle: t.t('checkoutUpiDesc'),
                      selected: _mode == PaymentMode.upi,
                      onTap: () => setState(() => _mode = PaymentMode.upi),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _PaymentOption(
                      icon: Icons.receipt_long_rounded,
                      title: t.t('checkoutUdhari'),
                      subtitle: t.t('checkoutUdhariDesc'),
                      selected: _mode == PaymentMode.udhari,
                      onTap: () => setState(() => _mode = PaymentMode.udhari),
                    ),

                    if (_mode == PaymentMode.upi) ...[
                      const SizedBox(height: AppSpacing.lg),
                      shopDetailsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (shop) {
                          final upiId = shop?['business_upi_id'] as String?;
                          if (upiId == null || upiId.isEmpty) {
                            return Text(
                              t.t('checkoutUpiDesc'),
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                            );
                          }
                          final shopName = shop?['shop_name'] as String? ?? 'Shop';
                          final upiUri = Uri(
                            scheme: 'upi',
                            host: 'pay',
                            queryParameters: {
                              'pa': upiId,
                              'pn': shopName,
                              'am': total.toStringAsFixed(2),
                              'cu': 'INR',
                            },
                          ).toString();
                          return Center(
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                children: [
                                  Text(t.t('checkoutUpiQrTitle'), style: AppTextStyles.label),
                                  const SizedBox(height: AppSpacing.md),
                                  QrImageView(
                                      data: upiUri, size: 160, backgroundColor: Colors.white),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(upiId, style: AppTextStyles.bodyMedium),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    t.t('checkoutUpiQrNote'),
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    if (checkoutState.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        t.t(checkoutState.errorMessage!),
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(t.t('checkoutOrderTotal'), style: AppTextStyles.label),
                        Text('₹${total.toStringAsFixed(0)}', style: AppTextStyles.priceLarge),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (checkoutState.isLoading || lines.isEmpty)
                          ? null
                          : _confirmAndPlaceOrder,
                      child: checkoutState.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(t.t('checkoutPlaceOrder')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FulfillmentOption extends StatelessWidget {
  const _FulfillmentOption({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderPlacedView extends StatelessWidget {
  const _OrderPlacedView({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration:
                    const BoxDecoration(color: AppColors.udhariClearBg, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: AppColors.udhariClear, size: 40),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(t.t('orderPlacedTitle'), style: AppTextStyles.h2, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              Text(
                t.t('orderPlacedSubtitle'),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('₹${order.total.toStringAsFixed(0)}', style: AppTextStyles.balanceAmount),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .popUntil((r) => r.settings.name == '/customer/home' || r.isFirst),
                  child: Text(t.t('orderPlacedContinueShopping')),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
