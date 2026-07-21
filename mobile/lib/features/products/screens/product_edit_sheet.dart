import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/product_models.dart';
import '../providers/product_provider.dart';

/// Add or edit a product. Category can be picked from the shop's
/// existing list or created inline — the owner shouldn't have to leave
/// this sheet to set one up first.
///
/// NOTE on images: image_picker gives a local file path. There's no
/// image-upload endpoint on the backend yet (see project TODOs), so for
/// now this stores the local file path as `imageUrl` directly, which
/// works for on-device preview but won't resolve on another device
/// until real upload (e.g. to Firebase Storage, already a dependency)
/// is wired up. That's a clearly-flagged follow-up, not a silent gap.
class ProductEditSheet extends ConsumerStatefulWidget {
  const ProductEditSheet({super.key, required this.shopId, this.product});

  final String shopId;
  final Product? product;

  @override
  ConsumerState<ProductEditSheet> createState() => _ProductEditSheetState();
}

class _ProductEditSheetState extends ConsumerState<ProductEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _unitController;
  String? _categoryId;
  String? _localImagePath;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController =
        TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '');
    _unitController = TextEditingController(text: p?.unit ?? '');
    _categoryId = p?.categoryId;
    _localImagePath = p?.imageUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) {
      setState(() => _localImagePath = file.path);
    }
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref.read(productFormProvider.notifier).saveProduct(
          existingId: widget.product?.id,
          shopId: widget.shopId,
          categoryId: _categoryId,
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          unit: _unitController.text.trim(),
          imageUrl: _localImagePath,
        );

    if (ok && mounted) {
      ref.read(productListProvider(widget.shopId).notifier).refresh();
      Navigator.of(context).pop();
    }
  }

  Future<void> _addCategoryDialog() async {
    final t = AppLocalizations.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.t('productCategoryAddNew')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: t.t('productCategoryNameHint')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(t.t('commonCancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(t.t('commonSave')),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final category = await ref
          .read(productFormProvider.notifier)
          .createCategory(shopId: widget.shopId, name: name);
      if (category != null) {
        ref.invalidate(categoriesProvider(widget.shopId));
        setState(() => _categoryId = category.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final formState = ref.watch(productFormProvider);
    final categoriesAsync = ref.watch(categoriesProvider(widget.shopId));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
        ),
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                Text(
                  _isEditing ? t.t('productEditTitle') : t.t('productAddTitle'),
                  style: AppTextStyles.h2,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Image picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 96,
                    width: 96,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _localImagePath == null
                        ? const Icon(Icons.add_a_photo_outlined,
                            color: AppColors.textMuted)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: _localImagePath!.startsWith('http')
                                ? Image.network(_localImagePath!, fit: BoxFit.cover)
                                : Image.file(File(_localImagePath!), fit: BoxFit.cover),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(t.t('productNameLabel'), style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(hintText: t.t('productNameHint')),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? t.t('productNameError') : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.t('productPriceLabel'), style: AppTextStyles.label),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(hintText: t.t('productPriceHint')),
                            validator: (v) {
                              final parsed = double.tryParse(v?.trim() ?? '');
                              if (parsed == null || parsed <= 0) {
                                return t.t('productPriceError');
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.t('productUnitLabel'), style: AppTextStyles.label),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _unitController,
                            decoration: InputDecoration(hintText: t.t('productUnitHint')),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? t.t('productUnitError')
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(t.t('productCategoryLabel'), style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.sm),
                categoriesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (categories) => Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      ChoiceChip(
                        label: Text(t.t('productCategoryNone')),
                        selected: _categoryId == null,
                        onSelected: (_) => setState(() => _categoryId = null),
                      ),
                      ...categories.map(
                        (c) => ChoiceChip(
                          label: Text(c.name),
                          selected: _categoryId == c.id,
                          onSelected: (_) => setState(() => _categoryId = c.id),
                        ),
                      ),
                      ActionChip(
                        label: Text(t.t('productCategoryAddNew')),
                        onPressed: _addCategoryDialog,
                      ),
                    ],
                  ),
                ),

                if (formState.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    t.t(formState.errorMessage!),
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
                  ),
                ],

                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: formState.isLoading ? null : _handleSave,
                    child: formState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(t.t('commonSave')),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
