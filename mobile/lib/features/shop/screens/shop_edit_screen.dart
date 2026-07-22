import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/picked_image_preview.dart';
import '../../../localization/app_localizations.dart';
import '../../../providers/session_provider.dart';
import '../providers/shop_provider.dart';

/// Makes good on the shop-setup screen's "you can edit it later"
/// promise. Pre-fills from the full shop record (session only carries
/// id/name/code, not address/UPI/contact/images), then saves via
/// PUT /shops/:id.
class ShopEditScreen extends ConsumerStatefulWidget {
  const ShopEditScreen({super.key});

  @override
  ConsumerState<ShopEditScreen> createState() => _ShopEditScreenState();
}

class _ShopEditScreenState extends ConsumerState<ShopEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _upiController = TextEditingController();
  final _contactController = TextEditingController();

  String? _shopImagePath;
  String? _upiQrImagePath;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _upiController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _prefillFrom(Map<String, dynamic> shop) {
    if (_prefilled) return;
    _nameController.text = shop['shop_name'] as String? ?? '';
    _addressController.text = shop['address'] as String? ?? '';
    _upiController.text = shop['business_upi_id'] as String? ?? '';
    _contactController.text = shop['contact_phone'] as String? ?? '';
    _shopImagePath = shop['shop_image_url'] as String?;
    _upiQrImagePath = shop['upi_qr_image_url'] as String?;
    _prefilled = true;
  }

  Future<void> _pickShopImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) setState(() => _shopImagePath = file.path);
  }

  Future<void> _pickUpiQrImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) setState(() => _upiQrImagePath = file.path);
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final session = ref.read(sessionProvider);
    final shopId = session.shopId;
    if (shopId == null) return;

    final t = AppLocalizations.of(context);
    final shop = await ref.read(shopActionProvider.notifier).updateShop(
          shopId: shopId,
          shopName: _nameController.text.trim(),
          address: _addressController.text.trim(),
          businessUpiId:
              _upiController.text.trim().isEmpty ? null : _upiController.text.trim(),
          contactPhone: _contactController.text.trim().isEmpty
              ? null
              : _contactController.text.trim(),
          shopImageUrl: _shopImagePath,
          upiQrImageUrl: _upiQrImagePath,
        );

    if (shop != null && mounted) {
      // Keep session in sync — the dashboard header reads shopName
      // straight from session, not from a re-fetch.
      ref.read(sessionProvider.notifier).setLinkedShop(
            shopId: shop['id'] as String,
            shopName: shop['shop_name'] as String,
            shopCode: shop['shop_code'] as String,
          );
      ref.invalidate(shopDetailsProvider(shop['shop_code'] as String));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.t('shopEditSaved'))),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider);
    final shopDetailsAsync = ref.watch(shopDetailsProvider(session.shopCode ?? ''));
    final actionState = ref.watch(shopActionProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.t('shopEditTitle'))),
      body: SafeArea(
        child: shopDetailsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(t.t('errorGeneric'))),
          data: (shop) {
            if (shop == null) return Center(child: Text(t.t('errorGeneric')));
            _prefillFrom(shop);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.t('shopImageLabel'), style: AppTextStyles.label),
                    const SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: _pickShopImage,
                      child: Container(
                        height: 96,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: _shopImagePath == null || _shopImagePath!.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_a_photo_outlined,
                                        color: AppColors.textMuted),
                                    const SizedBox(height: 4),
                                    Text(t.t('shopImagePick'), style: AppTextStyles.caption),
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                child: PickedImagePreview(
                                  path: _shopImagePath!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Text(t.t('shopNameLabel'), style: AppTextStyles.label),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(hintText: t.t('shopNameHint')),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? t.t('shopNameHint') : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Text(t.t('shopAddressLabel'), style: AppTextStyles.label),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: InputDecoration(hintText: t.t('shopAddressHint')),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Text(t.t('shopContactLabel'), style: AppTextStyles.label),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(hintText: t.t('shopContactHint')),
                      validator: (v) =>
                          Validators.phone(v, errorMessage: t.t('shopContactError')),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    Text(t.t('shopUpiLabel'), style: AppTextStyles.label),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _upiController,
                      decoration: InputDecoration(hintText: t.t('shopUpiHint')),
                      validator: (v) =>
                          Validators.upiId(v, errorMessage: t.t('shopUpiError')),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          child: Text(t.t('shopLinkOr'), style: AppTextStyles.caption),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Text(t.t('shopUpiQrImageLabel'), style: AppTextStyles.label),
                    const SizedBox(height: AppSpacing.sm),
                    GestureDetector(
                      onTap: _pickUpiQrImage,
                      child: Container(
                        height: 96,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: _upiQrImagePath == null || _upiQrImagePath!.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.qr_code_2_rounded,
                                        color: AppColors.textMuted),
                                    const SizedBox(height: 4),
                                    Text(t.t('shopUpiQrImagePick'),
                                        style: AppTextStyles.caption),
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                child: PickedImagePreview(
                                  path: _upiQrImagePath!,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                ),
                              ),
                      ),
                    ),

                    if (actionState.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        t.t(actionState.errorMessage!),
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: actionState.isLoading ? null : _handleSave,
                        child: actionState.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(t.t('shopEditSave')),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
