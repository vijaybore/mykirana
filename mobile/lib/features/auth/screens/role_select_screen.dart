import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/session_provider.dart' as session;

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  UserRole? _selectedRole;
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_selectedRole == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref
        .read(authProvider.notifier)
        .selectRole(_selectedRole!, _nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.step == AuthStep.done && previous?.step != AuthStep.done) {
        // Persist who's logged in before deciding where to send them —
        // shop setup/linking (and everything after) reads this.
        ref.read(session.sessionProvider.notifier).setUser(
              userId: next.userId!,
              role: next.role!,
            );

        if (next.role == UserRole.owner) {
          if (next.shopId != null &&
              next.shopName != null &&
              next.shopCode != null) {
            // Owner already has a shop (edge case: second device selected
            // role after shop was already created) — hydrate session and
            // go straight to the dashboard.
            ref.read(session.sessionProvider.notifier).setLinkedShop(
                  shopId: next.shopId!,
                  shopName: next.shopName!,
                  shopCode: next.shopCode!,
                );
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/owner/dashboard', (r) => false);
          } else {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/owner/shop-setup', (r) => false);
          }
        } else {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/customer/shop-link', (r) => false);
        }
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: AppSpacing.xl),
                Text(t.t('authRoleTitle'), style: AppTextStyles.h1),
                SizedBox(height: AppSpacing.sm),
                Text(
                  t.t('authRoleSubtitle'),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: AppSpacing.xl),

                _RoleCard(
                  icon: Icons.storefront_rounded,
                  title: t.t('authRoleOwnerTitle'),
                  description: t.t('authRoleOwnerDesc'),
                  selected: _selectedRole == UserRole.owner,
                  onTap: () => setState(() => _selectedRole = UserRole.owner),
                ),
                SizedBox(height: AppSpacing.md),
                _RoleCard(
                  icon: Icons.shopping_basket_rounded,
                  title: t.t('authRoleCustomerTitle'),
                  description: t.t('authRoleCustomerDesc'),
                  selected: _selectedRole == UserRole.customer,
                  onTap: () =>
                      setState(() => _selectedRole = UserRole.customer),
                ),

                SizedBox(height: AppSpacing.xl),

                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: _selectedRole == null
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.t('authRoleNameLabel'),
                              style: AppTextStyles.label,
                            ),
                            SizedBox(height: AppSpacing.sm),
                            TextFormField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              style: AppTextStyles.bodyLarge,
                              decoration: InputDecoration(
                                hintText: t.t('authRoleNameHint'),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return t.t('authRoleNameHint');
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                ),

                const Spacer(),

                if (authState.errorMessage != null) ...[
                  Text(
                    t.t(authState.errorMessage!),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.danger),
                  ),
                  SizedBox(height: AppSpacing.md),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_selectedRole == null || authState.isLoading)
                        ? null
                        : _handleContinue,
                    child: authState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(t.t('commonNext')),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.all(AppSpacing.lg),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.textSecondary,
                size: 24,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? AppColors.primary : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

