import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'package:image_picker/image_picker.dart';

/// A reusable image picker field with select/replace/delete actions.
///
/// Shows a placeholder tap target when no image is selected.
/// When an image is selected it shows the preview with an overlay
/// delete button (×) and tap-to-replace behaviour.
///
/// [onChanged] is called with the new local path, or null when deleted.
class ImagePickerField extends StatelessWidget {
  const ImagePickerField({
    super.key,
    required this.path,
    required this.onChanged,
    this.size = 100,
    this.placeholder,
    this.label,
  });

  final String? path;
  final ValueChanged<String?> onChanged;
  final double size;
  final Widget? placeholder;
  final String? label;

  Future<void> _pick(BuildContext context) async {
    // Show action sheet: Gallery or Camera
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            if (path != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove Image',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  onChanged(null);
                },
              ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      imageQuality: 72, // compress while keeping reasonable quality
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (file != null) {
      onChanged(file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: () => _pick(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: path == null
                    ? placeholder ??
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                size: 28),
                            const SizedBox(height: 4),
                            Text('Add Photo',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                          ],
                        )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: _ImageWidget(path: path!, size: size),
                      ),
              ),
              // Delete badge
              if (path != null)
                Positioned(
                  top: -8,
                  right: -8,
                  child: GestureDetector(
                    onTap: () => onChanged(null),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (path != null) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _pick(context),
            child: Text(
              'Tap to replace',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ImageWidget extends StatelessWidget {
  const _ImageWidget({required this.path, required this.size});
  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || path.startsWith('http')) {
      return Image.network(path,
          width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image_outlined, color: Colors.grey));
    }
    return Image.file(io.File(path),
        width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.broken_image_outlined, color: Colors.grey));
  }
}
