import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// QA ONLY — remove before release.
///
/// When true, BOTH compress attempts in [processImageForUpload] are treated as
/// null, forcing the `unprocessable` throw path to fire deterministically so
/// the case-3 (never-compressible photo) UX can be exercised on-device. Must
/// stay `false` in committed code — grep this name to delete.
const bool kSimulatePhotoUnprocessable = false;

/// Thrown by [processImageForUpload] when the source image cannot be
/// re-encoded even after a retry — i.e. it can NEVER be stripped/compressed
/// (e.g. a HEIC variant the native codec rejects). Callers catch this to mark
/// the photo unprocessable and steer the user to pick a different one, rather
/// than uploading the original with EXIF/GPS intact.
class ImageUnprocessableException implements Exception {
  const ImageUnprocessableException([this.message]);

  final String? message;

  @override
  String toString() =>
      'ImageUnprocessableException${message == null ? '' : ': $message'}';
}

/// Re-encodes [sourcePath] to JPEG at [targetPath] with a 1200px max edge,
/// stripping EXIF via the native iOS (CoreGraphics) / Android (libjpeg-turbo)
/// codecs. Returns the output File, or null if the native codec failed to
/// produce a result. The 1200 min-dimension floor and JPEG format are held
/// constant across attempts so a successful re-encode always yields the
/// B-2-verified output characteristics (and always strips EXIF).
Future<File?> _compressTo(
  String sourcePath,
  String targetPath, {
  required int quality,
}) async {
  if (kSimulatePhotoUnprocessable) return null; // QA ONLY — remove before release.
  final result = await FlutterImageCompress.compressAndGetFile(
    sourcePath,
    targetPath,
    quality: quality,
    minWidth: 1200,
    minHeight: 1200,
    format: CompressFormat.jpeg,
  );
  return result == null ? null : File(result.path);
}

/// Processes a photo for upload: resizes to a 1200px max edge, compresses to
/// JPEG, and strips EXIF — using the native codecs via `flutter_image_compress`,
/// which is 5–10x faster than pure-Dart decoding and already runs off the
/// platform thread.
///
/// Layered fallback (privacy-critical): the strip is what removes EXIF/GPS, so
/// on a compress failure we must NEVER fall back to the untouched original.
/// Instead we retry the re-encode once at a higher quality (keeping the 1200px
/// floor + JPEG so the retry still strips EXIF and preserves output
/// characteristics); if that ALSO fails the photo is genuinely unprocessable
/// and we throw [ImageUnprocessableException] so the caller can surface it.
///
/// [onCompressRetry] fires exactly when the first attempt returns null and the
/// retry is about to run — the caller uses it for telemetry (this path is the
/// dominant real-world case: iOS HEIC decode hiccups on ordinary photos).
///
/// `minWidth`/`minHeight` act as *max* constraints when the source is larger
/// (aspect ratio preserved, never upscaled); orientation is baked in. Returns a
/// new temp File — the original is never modified.
Future<File> processImageForUpload(
  File imageFile, {
  void Function()? onCompressRetry,
}) async {
  final tempDir = await getTemporaryDirectory();
  final sourcePath = imageFile.absolute.path;
  final targetPath =
      '${tempDir.path}/upload_${DateTime.now().microsecondsSinceEpoch}.jpg';

  final first = await _compressTo(sourcePath, targetPath, quality: 82);
  if (first != null) return first;

  // First attempt failed. Retry once with different params (still 1200px + JPEG
  // so EXIF is stripped and output characteristics are preserved). A separate
  // target path avoids reusing a possibly half-written file.
  onCompressRetry?.call();
  final retryPath =
      '${tempDir.path}/upload_${DateTime.now().microsecondsSinceEpoch}_r.jpg';
  final retry = await _compressTo(sourcePath, retryPath, quality: 95);
  if (retry != null) return retry;

  // Both attempts failed — the source can never be stripped. Fail closed:
  // throw so the original (EXIF intact) is NEVER uploaded.
  throw const ImageUnprocessableException();
}
