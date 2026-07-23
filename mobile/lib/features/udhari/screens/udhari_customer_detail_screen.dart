import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../providers/udhari_provider.dart';
import '../widgets/add_udhari_entry_sheet.dart';
import '../widgets/udhari_balance_card.dart';
import '../widgets/udhari_transaction_tile.dart';

class UdhariCustomerDetailScreen extends ConsumerWidget {
  const UdhariCustomerDetailScreen({
    super.key,
    required this.shopId,
    required this.customerId,
    required this.customerName,
  });

  final String shopId;
  final String customerId;
  final String customerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final args = (shopId: shopId, customerId: customerId);
    final historyAsync = ref.watch(udhariHistoryProvider(args));
    final notifier = ref.read(udhariHistoryProvider(args).notifier);

    return Scaffold(
      appBar: AppBar(title: Text(customerName)),
      body: historyAsync.when(
        loading: () => Shimmer.fromColors(
          baseColor: AppColors.skeletonBase,
          highlightColor: AppColors.skeletonHighlight,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.screenPadding),
            child: Column(
              children: [
                Container(height: 110, decoration: BoxDecoration(
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
          return ListView(
            padding: EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              UdhariBalanceCard(
                balance: notifier.balance,
                label: t.t('udhariTotalOwed'),
                clearLabel: t.t('udhariAllClear'),
              ),
              SizedBox(height: AppSpacing.xl),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AddUdhariEntrySheet.show(
            context,
            customerName: customerName,
            onSave: (type, amount, note) async {
              await notifier.addEntry(type: type, amount: amount, note: note);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.t('udhariSaved'))),
                );
              }
            },
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(t.t('udhariAddEntry')),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.textOnAccent,
      ),
    );
  }
}

