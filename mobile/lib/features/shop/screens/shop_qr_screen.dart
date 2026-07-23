import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../../../providers/session_provider.dart';

/// Lets the owner pull up their shop's QR/code any time — e.g. to show
/// a customer standing at the counter, separate from the one-time
/// "shop created" screen shown right after setup.
class ShopQrScreen extends ConsumerWidget {
  const ShopQrScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final shopCode = session.shopCode ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(t.t('shopQrTitle'))),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screenPadding),
            child: Container(
              padding: EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(session.shopName ?? '', style: AppTextStyles.h3),
                  SizedBox(height: AppSpacing.lg),
                  QrImageView(data: shopCode, size: 220, backgroundColor: Colors.white),
                  SizedBox(height: AppSpacing.lg),
                  Text(t.t('shopCodeLabel'), style: AppTextStyles.label),
                  const SizedBox(height: 4),
                  Text(shopCode, style: AppTextStyles.h1.copyWith(letterSpacing: 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
