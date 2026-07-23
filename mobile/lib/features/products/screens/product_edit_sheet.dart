import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/image_picker_field.dart';
import '../../../localization/app_localizations.dart';
import '../../../models/product_models.dart';
import '../providers/product_provider.dart';

// Preset unit options for the dropdown
const _kPresetUnits = [
  'Kg',
  'Gram (g)',
  'Litre (L)',
  'Millilitre (ml)',
  'Piece (pcs)',
  'Packet',
  'Bottle',
  'Box',
  'Bag',
  'Dozen',
  'Bundle',
  'Pack',
  'Custom...',
];

/// Add or edit a product with a professional Material 3 bottom sheet.
/// Unit is a dropdown with preset options + custom entry.
/// Image picker supports select / replace / delete with compression.
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
  late final TextEditingController _unitSizeController;
  final TextEditingController _customUnitController = TextEditingController();
  String? _categoryId;
  String? _localImagePath;
  String? _selectedUnit;
  bool _showCustomUnit = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _priceController =
        TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '');
    _categoryId = p?.categoryId;
    _localImagePath = p?.imageUrl;

    String initialUnit = p?.unit ?? '';
    String sizeText = '1';
    String? selectedUnitVal;

    // Parse out leading numbers/floats if present
    // E.g., "5 Kg", "500 Gram (g)", "1.5 Litre (L)"
    final match = RegExp(r'^([\d.]+)\s*(.*)$').firstMatch(initialUnit.trim());
    if (match != null) {
      sizeText = match.group(1) ?? '1';
      final parsedUnitName = match.group(2)?.trim() ?? '';
      if (_kPresetUnits.contains(parsedUnitName)) {
        selectedUnitVal = parsedUnitName;
      } else if (parsedUnitName.isNotEmpty) {
        selectedUnitVal = 'Custom...';
        _customUnitController.text = parsedUnitName;
        _showCustomUnit = true;
      }
    } else {
      if (_kPresetUnits.contains(initialUnit)) {
        selectedUnitVal = initialUnit;
      } else if (initialUnit.isNotEmpty) {
        selectedUnitVal = 'Custom...';
        _customUnitController.text = initialUnit;
        _showCustomUnit = true;
      }
    }

    _unitSizeController = TextEditingController(text: sizeText);
    _selectedUnit = selectedUnitVal;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _unitSizeController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  String? get _effectiveUnit {
    if (_selectedUnit == null) return null;
    final size = _unitSizeController.text.trim();
    final unitName = _selectedUnit == 'Custom...'
        ? _customUnitController.text.trim()
        : _selectedUnit!;
    
    if (unitName.isEmpty) return null;
    if (size.isEmpty || size == '1') {
      return unitName;
    }
    return '$size $unitName';
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final unit = _effectiveUnit;
    if (unit == null) return;

    final ok = await ref.read(productFormProvider.notifier).saveProduct(
          existingId: widget.product?.id,
          shopId: widget.shopId,
          categoryId: _categoryId,
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          unit: unit,
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
          FilledButton(
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
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing ? t.t('productEditTitle') : t.t('productAddTitle'),
                        style: AppTextStyles.h2,
                      ),
                    ),
                    if (_isEditing)
                      IconButton(
                        onPressed: formState.isLoading ? null : _handleSave,
                        icon: const Icon(Icons.check_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Image picker
                ImagePickerField(
                  path: _localImagePath,
                  size: 100,
                  label: 'Product Photo (optional)',
                  onChanged: (p) => setState(() => _localImagePath = p),
                ),
                const SizedBox(height: 24),

                // Product Name
                _SectionLabel(t.t('productNameLabel')),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: t.t('productNameHint'),
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? t.t('productNameError') : null,
                ),
                const SizedBox(height: 16),

                // Product Price
                _SectionLabel(t.t('productPriceLabel')),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                    hintText: '0',
                  ),
                  validator: (v) {
                    final parsed = double.tryParse(v?.trim() ?? '');
                    if (parsed == null || parsed <= 0) {
                      return t.t('productPriceError');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Unit Configuration Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unit Quantity / Size (e.g. 5, 500, 1)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel('Size / Qty'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _unitSizeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                            ],
                            decoration: const InputDecoration(
                              hintText: '1',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
                              final parsed = double.tryParse(v.trim());
                              if (parsed == null || parsed <= 0) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Unit dropdown
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(t.t('productUnitLabel')),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedUnit,
                            isExpanded: true,
                            hint: Text(t.t('productUnitHint')),
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.scale_outlined),
                            ),
                            items: _kPresetUnits
                                .map((u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u, overflow: TextOverflow.ellipsis),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedUnit = val;
                                _showCustomUnit = val == 'Custom...';
                                if (!_showCustomUnit) _customUnitController.clear();
                              });
                            },
                            validator: (_) =>
                                _selectedUnit == null ? t.t('productUnitError') : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Custom unit text field (visible only when "Custom..." selected)
                if (_showCustomUnit) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customUnitController,
                    decoration: const InputDecoration(
                      labelText: 'Enter custom unit',
                      hintText: 'e.g. 500ml, roll, sheet',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                    validator: (v) {
                      if (_showCustomUnit && (v == null || v.trim().isEmpty)) {
                        return 'Please enter a unit name';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),

                // Category
                _SectionLabel(t.t('productCategoryLabel')),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (categories) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text(t.t('productCategoryNone')),
                        selected: _categoryId == null,
                        onSelected: (_) => setState(() => _categoryId = null),
                        selectedColor: AppColors.primaryLight,
                        checkmarkColor: AppColors.primary,
                      ),
                      ...categories.map(
                        (c) => FilterChip(
                          label: Text(c.name),
                          selected: _categoryId == c.id,
                          onSelected: (_) => setState(() => _categoryId = c.id),
                          selectedColor: AppColors.primaryLight,
                          checkmarkColor: AppColors.primary,
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: Text(t.t('productCategoryAddNew')),
                        onPressed: _addCategoryDialog,
                      ),
                    ],
                  ),
                ),

                // Error message
                if (formState.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formState.errorMessage!,
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: formState.isLoading ? null : _handleSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: formState.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            t.t('commonSave'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.label,
      );
}
