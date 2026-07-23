import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../../../providers/session_provider.dart';
import '../providers/udhari_provider.dart';
import '../widgets/udhari_balance_card.dart';
import '../widgets/udhari_transaction_tile.dart';

/// Customer's own udhari view — "kitna udhaar hai mera?" answered
/// instantly, with the full history of what was taken and paid.
/// Read-only: only the shop owner can add entries.
class MyUdhariScreen extends ConsumerWidget {
  const MyUdhariScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final shopId = session.shopId ?? '';
    final customerId = session.userId ?? '';
    final args = (shopId: shopId, customerId: customerId);
    final historyAsync = ref.watch(udhariHistoryProvider(args));
    final notifier = ref.read(udhariHistoryProvider(args).notifier);

    return Scaffold(
      appBar: AppBar(title: Text(t.t('udhariMyBalance'))),
      body: historyAsync.when(
        loading: () => Shimmer.fromColors(
          baseColor: AppColors.skeletonBase,
          highlightColor: AppColors.skeletonHighlight,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              children: [
                Container(height: 120, decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                )),
                SizedBox(height: AppSpacing.xl),
                for (int i = 0; i < 4; i++)
                  Container(
                    height: 56,
                    margin: EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
              ],
            ),
          ),
        ),
        error: (_, __) => Center(child: Text(t.t('errorGeneric'))),
        data: (history) {
          return RefreshIndicator(
            onRefresh: () async {
              // Re-trigger via provider rebuild
              ref.invalidate(udhariHistoryProvider(args));
            },
            child: ListView(
              padding: EdgeInsets.all(AppSpacing.screenPadding),
              children: [
                UdhariBalanceCard(
                  balance: notifier.balance,
                  label: t.t('udhariMyBalanceOwing'),
                  clearLabel: t.t('udhariMyBalanceClear'),
                ),
                SizedBox(height: AppSpacing.xl),
                Text(t.t('navUdhari'), style: AppTextStyles.h3),
                SizedBox(height: AppSpacing.sm),
                if (history.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Center(
                      child: Text(
                        t.t('udhariHistoryEmpty'),
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...history.map(
                    (txn) => UdhariTransactionTile(transaction: txn),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

