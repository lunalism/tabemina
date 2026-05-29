import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Processes a photo for upload: resizes to a 1200px max edge, compresses to
/// JPEG quality 82, and strips EXIF — using the native iOS (CoreGraphics) /
/// Android (libjpeg-turbo) codecs via `flutter_image_compress`, which is
/// 5–10x faster than pure-Dart decoding and already runs off the platform
/// thread.
///
/// `minWidth`/`minHeight` act as *max* constraints when the source is
/// larger (aspect ratio preserved, never upscaled); EXIF is stripped and
/// orientation baked in by default. Returns a new temp File — the original
/// is never modified. Falls back to the original on failure so the upload
/// can still proceed.
Future<File> processImageForUpload(File imageFile) async {
  final tempDir = await getTemporaryDirectory();
  final targetPath =
      '${tempDir.path}/upload_${DateTime.now().microsecondsSinceEpoch}.jpg';

  final result = await FlutterImageCompress.compressAndGetFile(
    imageFile.absolute.path,
    targetPath,
    quality: 82,
    minWidth: 1200,
    minHeight: 1200,
    format: CompressFormat.jpeg,
  );

  if (result == null) return imageFile; // fallback: original
  return File(result.path);
}
