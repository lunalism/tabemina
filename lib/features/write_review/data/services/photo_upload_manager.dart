import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/analytics/analytics_events.dart';
import '../../../../core/utils/image_utils.dart';
import '../../domain/models/photo_upload_state.dart';

/// Drives the Instagram-style pre-upload flow: photos are processed and
/// uploaded to Firebase Storage the moment they're picked, so by the time
/// the user taps Post the URLs are already available and the submit is just
/// a Firestore write.
///
/// One instance lives per write-review session (created in the screen's
/// State, disposed with it). UI listens to [photosNotifier].
class PhotoUploadManager {
  // Public `analytics:` param name over a private field; a `this._analytics`
  // initializing formal would leak the underscore to call sites.
  PhotoUploadManager({FirebaseStorage? storage, AnalyticsEvents? analytics})
      : _storage = storage ?? FirebaseStorage.instance,
        // ignore: prefer_initializing_formals
        _analytics = analytics;

  final FirebaseStorage _storage;

  /// Optional telemetry for the compress-fallback path (retry / unprocessable).
  /// Null in tests; wired from the screen in production.
  final AnalyticsEvents? _analytics;
  final List<PhotoUploadState> _photos = [];

  /// URLs of existing photos the user removed during an edit — deleted from
  /// Storage only when the edit is saved (so cancelling the edit is safe).
  final List<String> _removedExistingUrls = [];

  /// Storage object paths for those removed existing photos, when known
  /// (reviews saved with path tracking). Preferred over URL-based deletion.
  final List<String> _removedExistingStoragePaths = [];

  final ValueNotifier<List<PhotoUploadState>> photosNotifier =
      ValueNotifier(const []);

  // In-flight uploads are fire-and-forget; they may complete after the
  // screen (and this manager) is disposed. Guard the notifier so a late
  // callback doesn't set a disposed ValueNotifier.
  bool _disposed = false;

  /// Permanent path — no temp/move dance. Kept to TWO segments under
  /// `reviews/` (`{userId}/{localId}.jpg`) so it matches the deployed
  /// Storage rule `match /reviews/{reviewId}/{fileName}`; a three-segment
  /// path (…/photos/…) isn't covered by that rule and gets rejected with
  /// `unauthorized`.
  String _storagePathFor(String userId, String localId) =>
      'reviews/$userId/$localId.jpg';

  // ---- Queries -------------------------------------------------------------

  bool get allPhotosReady =>
      _photos.every((p) => p.status == PhotoUploadStatus.completed);

  bool get hasActiveUploads => _photos.any((p) =>
      p.status == PhotoUploadStatus.processing ||
      p.status == PhotoUploadStatus.uploading);

  bool get hasFailedUploads =>
      _photos.any((p) => p.status == PhotoUploadStatus.failed);

  bool get isEmpty => _photos.isEmpty;

  int get count => _photos.length;

  /// All completed URLs in display order (existing kept + newly uploaded).
  List<String> get completedUrls => _photos
      .where((p) => p.status == PhotoUploadStatus.completed)
      .map((p) => p.downloadUrl!)
      .toList();

  /// Storage object paths for the completed photos that have one (new
  /// uploads always do; existing photos do when the review was saved with
  /// path tracking). Persisted on the review doc so the blobs can be
  /// deleted later.
  List<String> get completedStoragePaths => _photos
      .where((p) =>
          p.status == PhotoUploadStatus.completed && p.storagePath != null)
      .map((p) => p.storagePath!)
      .toList();

  /// Existing-photo URLs the user removed during this edit session.
  List<String> get removedExistingUrls => List.unmodifiable(_removedExistingUrls);

  /// Storage paths for removed existing photos that had one tracked.
  List<String> get removedExistingStoragePaths =>
      List.unmodifiable(_removedExistingStoragePaths);

  // ---- Mutations -----------------------------------------------------------

  /// Seed the manager with an edited review's existing photos. They show as
  /// completed immediately and are never re-uploaded. [existingStoragePaths]
  /// (parallel to [existingUrls], when available) lets a later removal delete
  /// the exact blob; older reviews without stored paths fall back to
  /// URL-based deletion.
  void loadExistingPhotos(
    List<String> existingUrls, [
    List<String> existingStoragePaths = const [],
  ]) {
    for (var i = 0; i < existingUrls.length; i++) {
      _photos.add(PhotoUploadState(
        localId: 'existing_$i',
        originalFile: File(''),
        status: PhotoUploadStatus.completed,
        downloadUrl: existingUrls[i],
        storagePath:
            i < existingStoragePaths.length ? existingStoragePaths[i] : null,
        uploadProgress: 1.0,
        isExisting: true,
      ));
    }
    _notify();
  }

  /// Pick → process → upload, immediately. Updates [photosNotifier] across
  /// each lifecycle transition.
  Future<void> addPhoto(File file, String userId) async {
    final localId = DateTime.now().microsecondsSinceEpoch.toString();
    _photos.add(PhotoUploadState(
      localId: localId,
      originalFile: file,
      status: PhotoUploadStatus.processing,
    ));
    _notify();

    try {
      final processed = await processImageForUpload(
        file,
        onCompressRetry: () => _analytics?.photoCompressRetry(),
      );
      _update(localId, (s) => s.copyWith(
            processedFile: processed,
            status: PhotoUploadStatus.uploading,
          ));

      final storagePath = _storagePathFor(userId, localId);
      final ref = _storage.ref(storagePath);
      final task = ref.putFile(
        processed,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      task.snapshotEvents.listen((snap) {
        if (snap.totalBytes <= 0) return;
        _update(
          localId,
          (s) => s.copyWith(
            uploadProgress: snap.bytesTransferred / snap.totalBytes,
          ),
        );
      });
      await task;
      final url = await ref.getDownloadURL();

      _update(localId, (s) => s.copyWith(
            status: PhotoUploadStatus.completed,
            downloadUrl: url,
            storagePath: storagePath,
            uploadProgress: 1.0,
          ));

      if (processed.path != file.path) {
        processed.delete().catchError((_) => processed);
      }
    } catch (e) {
      // An unprocessable image can NEVER be re-encoded/stripped — retry is
      // pointless, so classify it distinctly and steer the user to a different
      // photo. Everything else (e.g. upload network errors) is transient.
      final unprocessable = e is ImageUnprocessableException;
      if (unprocessable) _analytics?.photoCompressUnprocessable();
      _update(localId, (s) => s.copyWith(
            status: PhotoUploadStatus.failed,
            error: e.toString(),
            failureKind: unprocessable
                ? PhotoFailureKind.unprocessable
                : PhotoFailureKind.transient,
          ));
    }
  }

  /// Remove a photo. Existing (edit-mode) photos are tracked for deletion on
  /// save; newly-uploaded ones are deleted from Storage right away.
  Future<void> removePhoto(String localId) async {
    final index = _photos.indexWhere((p) => p.localId == localId);
    if (index < 0) return;
    final photo = _photos[index];

    if (photo.isExisting) {
      if (photo.downloadUrl != null) {
        _removedExistingUrls.add(photo.downloadUrl!);
      }
      if (photo.storagePath != null) {
        _removedExistingStoragePaths.add(photo.storagePath!);
      }
    } else {
      if (photo.storagePath != null) {
        _storage.ref(photo.storagePath!).delete().catchError((_) {});
      }
      final processed = photo.processedFile;
      if (processed != null && processed.path != photo.originalFile.path) {
        processed.delete().catchError((_) => processed);
      }
    }

    _photos.removeAt(index);
    _notify();
  }

  /// Retry a failed photo by re-running the whole add flow.
  Future<void> retryPhoto(String localId, String userId) async {
    final index = _photos.indexWhere((p) => p.localId == localId);
    if (index < 0) return;
    final photo = _photos[index];
    if (photo.status != PhotoUploadStatus.failed) return;
    _photos.removeAt(index);
    _notify();
    await addPhoto(photo.originalFile, userId);
  }

  /// Retry every failed photo.
  Future<void> retryAllFailed(String userId) async {
    final failed = _photos
        .where((p) => p.status == PhotoUploadStatus.failed)
        .toList();
    for (final p in failed) {
      await retryPhoto(p.localId, userId);
    }
  }

  /// Clear the removed-existing tracking after a successful edit save. The
  /// actual Storage deletes are performed by
  /// `ReviewRepository.updateReview` (by path, with a URL fallback), so this
  /// just drops the now-committed bookkeeping.
  Future<void> commitRemovals() async {
    _removedExistingUrls.clear();
    _removedExistingStoragePaths.clear();
  }

  /// Abandon: delete every uploaded (non-existing) photo from Storage and
  /// clear local temp files. Existing photos are left untouched.
  Future<void> cancelAll() async {
    for (final photo in _photos) {
      if (photo.isExisting) continue;
      if (photo.storagePath != null) {
        _storage.ref(photo.storagePath!).delete().catchError((_) {});
      }
      final processed = photo.processedFile;
      if (processed != null && processed.path != photo.originalFile.path) {
        processed.delete().catchError((_) => processed);
      }
    }
    _photos.clear();
    _notify();
  }

  void _update(
    String localId,
    PhotoUploadState Function(PhotoUploadState) updater,
  ) {
    if (_disposed) return;
    final index = _photos.indexWhere((p) => p.localId == localId);
    if (index >= 0) {
      _photos[index] = updater(_photos[index]);
      _notify();
    }
  }

  void _notify() {
    if (_disposed) return;
    photosNotifier.value = List.unmodifiable(_photos);
  }

  void dispose() {
    _disposed = true;
    photosNotifier.dispose();
  }
}
