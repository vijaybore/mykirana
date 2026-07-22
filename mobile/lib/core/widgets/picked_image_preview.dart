import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
// Guarded by kIsWeb at every call site — dart:io's File is unavailable
// on web, but the import itself is fine since we never construct a
// File when kIsWeb is true.
import 'dart:io' as io;

/// Displays a locally-picked image (from image_picker) regardless of
/// platform.
///
/// image_picker returns a path that means different things per
/// platform: on mobile/desktop it's a real filesystem path, which
/// needs `Image.file`. On web it's actually a blob: URL, which
/// `Image.network` already knows how to load directly — `Image.file`
/// throws a hard assertion on web ("Image.file is not supported on
/// Flutter Web"), which is what was crashing the shop-setup and
/// product-photo screens.
///
/// Also transparently handles a path that's already a real network
/// URL (e.g. a previously-saved product image), so callers don't need
/// their own branching for "local pick" vs "existing URL".
class PickedImagePreview extends StatelessWidget {
  const PickedImagePreview({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image_outlined,
          color: Colors.grey,
        ),
      );
    }
    return Image.file(
      io.File(path),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.broken_image_outlined,
        color: Colors.grey,
      ),
    );
  }
}
