import 'dart:io';

import 'package:flutter/foundation.dart';

enum PhotoUploadStatus {
  /// Image is being resized / compressed / EXIF-stripped.
  processing,

  /// Processed file is uploading to Firebase Storage.
  uploading,

  /// Upload finished — [PhotoUploadState.downloadUrl] is available.
  completed,

  /// Processing or upload failed — the user can retry.
  failed,
}

/// Why a [PhotoUploadStatus.failed] photo failed — drives whether the UI offers
/// retry or steers the user to a different photo.
enum PhotoFailureKind {
  /// A recoverable failure (e.g. a network hiccup during upload). Retrying the
  /// same file can succeed — the default when the reason is unknown.
  transient,

  /// The image can never be re-encoded/stripped (compress failed after a
  /// retry). Retrying is pointless; the user must pick a different photo.
  unprocessable,
}

/// One photo's lifecycle in the Instagram-style pre-upload flow: each photo
/// is processed and uploaded the moment it's picked, so posting the review
/// is just a Firestore write.
@immutable
class PhotoUploadState {
  const PhotoUploadState({
    required this.localId,
    required this.originalFile,
    required this.status,
    this.processedFile,
    this.downloadUrl,
    this.storagePath,
    this.uploadProgress = 0.0,
    this.error,
    this.failureKind,
    this.isExisting = false,
  });

  /// Stable per-session id (timestamp-based for new photos,
  /// `existing_*` for ones loaded from an edited review).
  final String localId;

  /// The picked file. For [isExisting] entries this is a placeholder.
  final File originalFile;

  /// Resized/compressed temp file (null until processing completes).
  final File? processedFile;

  /// Firebase Storage download URL — set when [status] is completed.
  final String? downloadUrl;

  /// Firebase Storage path, for deletion. Null for [isExisting] photos
  /// (we don't track their original storage path).
  final String? storagePath;

  final PhotoUploadStatus status;

  /// 0.0–1.0 for the upload portion.
  final double uploadProgress;

  final String? error;

  /// Set when [status] is [PhotoUploadStatus.failed] — classifies the failure
  /// so the UI can offer retry (transient) vs. "use a different photo"
  /// (unprocessable). Null when not failed, or when the reason is unknown
  /// (treated as transient).
  final PhotoFailureKind? failureKind;

  /// True when this entry came from an existing review being edited — it's
  /// already on the server, shows as completed immediately, and is never
  /// re-uploaded.
  final bool isExisting;

  PhotoUploadState copyWith({
    File? processedFile,
    String? downloadUrl,
    String? storagePath,
    PhotoUploadStatus? status,
    double? uploadProgress,
    String? error,
    PhotoFailureKind? failureKind,
  }) {
    return PhotoUploadState(
      localId: localId,
      originalFile: originalFile,
      isExisting: isExisting,
      processedFile: processedFile ?? this.processedFile,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      storagePath: storagePath ?? this.storagePath,
      status: status ?? this.status,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      error: error ?? this.error,
      failureKind: failureKind ?? this.failureKind,
    );
  }
}
