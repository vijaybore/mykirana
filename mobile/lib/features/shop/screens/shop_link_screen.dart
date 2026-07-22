import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../../../providers/session_provider.dart';
import '../providers/shop_provider.dart';

/// Step 6 — customer scans the shop's QR or types its code. Once
/// linked, session.setLinkedShop() persists it, so this screen is
/// only ever seen once per customer (per the "always there" plan).
class ShopLinkScreen extends ConsumerStatefulWidget {
  const ShopLinkScreen({super.key});

  @override
  ConsumerState<ShopLinkScreen> createState() => _ShopLinkScreenState();
}

class _ShopLinkScreenState extends ConsumerState<ShopLinkScreen> {
  final _codeController = TextEditingController();
  bool _scannerOpen = false;
  bool _handledScan = false; // guards against multiple rapid callbacks

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _connect(String code) async {
    if (code.trim().isEmpty) return;

    final session = ref.read(sessionProvider);
    // Customers may be guests (no userId yet) — that's fine, shop linking
    // doesn't require a user record; the customer's profile is created at checkout.
    final customerId = session.userId ?? 'guest';

    final shop = await ref.read(shopActionProvider.notifier).linkToShopByCode(
          customerId: customerId,
          code: code,
        );

    if (shop != null) {
      ref.read(sessionProvider.notifier).setLinkedShop(
            shopId: shop['id'] as String,
            shopName: shop['shop_name'] as String,
            shopCode: shop['shop_code'] as String,
          );
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/customer/home', (r) => false);
      }
    }
  }

  void _openScanner() {
    setState(() {
      _scannerOpen = true;
      _handledScan = false;
    });
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_handledScan) return;
    if (capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;
    _handledScan = true;
    setState(() => _scannerOpen = false);
    _connect(value);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final actionState = ref.watch(shopActionProvider);

    if (_scannerOpen) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.t('shopLinkScan')),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => setState(() => _scannerOpen = false),
          ),
        ),
        body: Stack(
          children: [
            MobileScanner(onDetect: _handleDetect),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                color: Colors.black54,
                child: Text(
                  t.t('shopLinkScanning'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('shopLinkTitle')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil('/', (r) => false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                t.t('shopLinkSubtitle'),
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Primary action: scan
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: actionState.isLoading ? null : _openScanner,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(t.t('shopLinkScan')),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(t.t('shopLinkOr'), style: AppTextStyles.caption),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(t.t('shopLinkCodeLabel'), style: AppTextStyles.label),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                style: AppTextStyles.h3,
                decoration: InputDecoration(
                  hintText: t.t('shopLinkCodeHint'),
                ),
              ),

              if (actionState.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  t.t(actionState.errorMessage!),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.danger),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: actionState.isLoading
                      ? null
                      : () => _connect(_codeController.text),
                  child: actionState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(t.t('shopLinkConnect')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

