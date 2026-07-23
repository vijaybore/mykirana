import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/screen_util.dart';
import '../../../core/widgets/picked_image_preview.dart';
import '../../../core/utils/validators.dart';
import '../../../localization/app_localizations.dart';
import '../../../providers/session_provider.dart';
import '../providers/shop_provider.dart';

/// Step 4 — owner fills in shop name/address/contact/UPI/photos, we
/// create the shop and generate its code + QR, then the owner lands on
/// this same screen's "created" state before continuing to the dashboard.
///
/// NOTE on the two image fields (shop photo, UPI QR photo): like the
/// product photo picker, there's no image-upload endpoint on the
/// backend yet, so the local file path is stored as-is. This previews
/// fine on this device but won't resolve on another device/session
/// until real upload (e.g. Firebase Storage, already a dependency) is
/// wired up — a flagged follow-up, not a silent gap.
class ShopSetupScreen extends ConsumerStatefulWidget {
  const ShopSetupScreen({super.key});

  @override
  ConsumerState<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends ConsumerState<ShopSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _upiController = TextEditingController();
  final _contactController = TextEditingController();

  String? _shopImagePath;
  String? _upiQrImagePath;

  Map<String, dynamic>? _createdShop;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _upiController.dispose();
    _contactController.dispose();
    super.dispose();
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

  Future<void> _handleCreate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final session = ref.read(sessionProvider);
    final ownerId = session.userId ?? 'default_owner';

    final shop = await ref.read(shopActionProvider.notifier).createShop(
          ownerId: ownerId,
          shopName: _nameController.text.trim(),
          address: _addressController.text.trim(),
          businessUpiId: _upiController.text.trim().isEmpty
              ? null
              : _upiController.text.trim(),
          contactPhone: _contactController.text.trim().isEmpty
              ? null
              : _contactController.text.trim(),
          shopImageUrl: _shopImagePath,
          upiQrImageUrl: _upiQrImagePath,
        );

    if (shop != null) {
      ref.read(sessionProvider.notifier).setLinkedShop(
            shopId: shop['id'] as String,
            shopName: shop['shop_name'] as String,
            shopCode: shop['shop_code'] as String,
          );
      setState(() => _createdShop = shop);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final actionState = ref.watch(shopActionProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(t.t('shopSetupTitle')),
      ),
      body: SafeArea(
        child: _createdShop != null
            ? Padding(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: _ShopCreatedView(
                  shop: _createdShop!,
                  onContinue: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/owner/dashboard', (r) => false),
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.screenPadding),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.t('shopSetupSubtitle'),
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: AppSpacing.xl),

                      // Shop photo
                      Text(t.t('shopImageLabel'), style: AppTextStyles.label),
                      SizedBox(height: AppSpacing.sm),
                      GestureDetector(
                        onTap: _pickShopImage,
                        child: Container(
                          height: ScreenUtil.dp(96),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: _shopImagePath == null
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.add_a_photo_outlined,
                                          color: AppColors.textMuted),
                                      const SizedBox(height: 4),
                                      Text(t.t('shopImagePick'),
                                          style: AppTextStyles.caption),
                                    ],
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  child: PickedImagePreview(
                                      path: _shopImagePath!,
                                      fit: BoxFit.cover, width: double.infinity),
                                ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),

                      Text(t.t('shopNameLabel'), style: AppTextStyles.label),
                      SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: t.t('shopNameHint'),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? t.t('shopNameHint')
                            : null,
                      ),
                      SizedBox(height: AppSpacing.lg),

                      Text(t.t('shopAddressLabel'), style: AppTextStyles.label),
                      SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: t.t('shopAddressHint'),
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),

                      Text(t.t('shopContactLabel'), style: AppTextStyles.label),
                      SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _contactController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: t.t('shopContactHint'),
                        ),
                        validator: (v) => Validators.phone(
                          v,
                          errorMessage: t.t('shopContactError'),
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),

                      Text(t.t('shopUpiLabel'), style: AppTextStyles.label),
                      SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _upiController,
                        decoration: InputDecoration(
                          hintText: t.t('shopUpiHint'),
                        ),
                        validator: (v) => Validators.upiId(
                          v,
                          errorMessage: t.t('shopUpiError'),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        t.t('shopUpiNote'),
                        style: AppTextStyles.caption,
                      ),
                      SizedBox(height: AppSpacing.md),

                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                            child: Text(t.t('shopLinkOr'), style: AppTextStyles.caption),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      SizedBox(height: AppSpacing.md),

                      Text(t.t('shopUpiQrImageLabel'), style: AppTextStyles.label),
                      SizedBox(height: AppSpacing.sm),
                      GestureDetector(
                        onTap: _pickUpiQrImage,
                        child: Container(
                          height: ScreenUtil.dp(96),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: _upiQrImagePath == null
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
                                      fit: BoxFit.contain, width: double.infinity),
                                ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(t.t('shopUpiQrImageNote'), style: AppTextStyles.caption),

                      if (actionState.errorMessage != null) ...[
                        SizedBox(height: AppSpacing.md),
                        Container(
                          padding: EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                              SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  t.t(actionState.errorMessage!),
                                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              actionState.isLoading ? null : _handleCreate,
                          child: actionState.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(t.t('shopSetupCreate')),
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

class _ShopCreatedView extends StatelessWidget {
  const _ShopCreatedView({required this.shop, required this.onContinue});

  final Map<String, dynamic> shop;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final shopCode = shop['shop_code'] as String;

    return Column(
      children: [
        SizedBox(height: AppSpacing.xl),
        Container(
          width: ScreenUtil.dp(72),
          height: ScreenUtil.dp(72),
          decoration: BoxDecoration(
            color: AppColors.udhariClearBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              color: AppColors.udhariClear, size: 40),
        ),
        SizedBox(height: AppSpacing.lg),
        Text(t.t('shopCreatedTitle'), style: AppTextStyles.h2,
            textAlign: TextAlign.center),
        SizedBox(height: AppSpacing.xs),
        Text(
          t.t('shopCreatedSubtitle'),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        SizedBox(height: AppSpacing.xl),

        Container(
          padding: EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              QrImageView(
                data: shopCode,
                size: ScreenUtil.dp(180),
                backgroundColor: Colors.white,
              ),
              SizedBox(height: AppSpacing.lg),
              Text(t.t('shopCodeLabel'), style: AppTextStyles.label),
              const SizedBox(height: 4),
              Text(
                shopCode,
                style: AppTextStyles.h1.copyWith(letterSpacing: 2),
              ),
            ],
          ),
        ),

        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onContinue,
            child: Text(t.t('shopContinue')),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
