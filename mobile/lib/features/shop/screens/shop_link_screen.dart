import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../../../providers/session_provider.dart';
import '../providers/shop_provider.dart';

/// Customer scans the shop's QR or types its code to connect.
/// This screen is only ever shown once — after linking, the session
/// persists the shop and the customer goes straight to the catalog.
class ShopLinkScreen extends ConsumerStatefulWidget {
  const ShopLinkScreen({super.key});

  @override
  ConsumerState<ShopLinkScreen> createState() => _ShopLinkScreenState();
}

class _ShopLinkScreenState extends ConsumerState<ShopLinkScreen>
    with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  bool _scannerOpen = false;
  bool _handledScan = false;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  List<Map<String, String>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  Future<void> _loadHistory() async {
    final history = await ref.read(localPrefsProvider).getVisitedShops();
    if (mounted) setState(() => _history = history);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect(String code) async {
    if (code.trim().isEmpty) return;
    final session = ref.read(sessionProvider);
    final customerId = session.userId ?? 'guest';

    final shop = await ref.read(shopActionProvider.notifier).linkToShopByCode(
          customerId: customerId,
          code: code,
        );

    if (shop != null) {
      await ref.read(localPrefsProvider).addVisitedShop(
            shopId: shop['id'] as String,
            shopName: shop['shop_name'] as String,
            shopCode: shop['shop_code'] as String,
          );
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
    final size = MediaQuery.of(context).size;

    // Full-screen QR scanner
    if (_scannerOpen) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(t.t('shopLinkScan'),
              style: const TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => setState(() => _scannerOpen = false),
          ),
        ),
        body: Stack(
          children: [
            MobileScanner(onDetect: _handleDetect),
            // Viewfinder overlay
            Center(
              child: Container(
                width: size.width * 0.65,
                height: size.width * 0.65,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // Bottom label
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  t.t('shopLinkScanning'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(t.t('shopLinkTitle'),
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil('/', (r) => false),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.lg,
              AppSpacing.screenPadding,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Illustration header
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded,
                        color: Colors.white, size: 48),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  t.t('shopLinkSubtitle'),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Primary: Scan QR
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: actionState.isLoading ? null : _openScanner,
                    icon: const Icon(Icons.qr_code_rounded),
                    label: Text(
                      t.t('shopLinkScan'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(t.t('shopLinkOr'),
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textMuted)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                // Manual code entry card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.t('shopLinkCodeLabel'), style: AppTextStyles.label),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        style: AppTextStyles.h3.copyWith(letterSpacing: 3),
                        decoration: InputDecoration(
                          hintText: t.t('shopLinkCodeHint'),
                          hintStyle: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.textMuted, letterSpacing: 1),
                          prefixIcon: const Icon(Icons.storefront_outlined),
                          suffixIcon: _codeController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _codeController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),

                      // Error
                      if (actionState.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: AppColors.danger, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t.t(actionState.errorMessage!),
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.danger),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: actionState.isLoading
                              ? null
                              : () => _connect(_codeController.text),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: actionState.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Text(
                                  t.t('shopLinkConnect'),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Recent shops history
                if (_history.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Icon(Icons.history_rounded,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        t.t('settingsRecentlyVisited'),
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final shop = _history[i];
                      return InkWell(
                        onTap: () => _connect(shop['code'] ?? ''),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.storefront_rounded,
                                    color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shop['name'] ?? '',
                                      style: AppTextStyles.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      shop['code'] ?? '',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textMuted,
                                        letterSpacing: 1.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded,
                                  size: 14, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
