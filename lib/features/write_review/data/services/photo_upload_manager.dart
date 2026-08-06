import 'dart:async';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/analytics/analytics_events.dart';
import '../../../../core/utils/image_utils.dart';
import '../../domain/models/photo_upload_state.dart';

/// Wall-clock ceiling for a single photo upload.
///
/// Rationale (argued, not measured): review photos are ~1200px / q82 JPEG, i.e.
/// a few hundred KB. At ~100 kbps a 300 KB object takes roughly 24s, so 60s
/// leaves headroom for a bad-but-alive link while still bounding a stuck
/// transfer. This is deliberately NOT in the same family as the existing 10s
/// constants in this codebase (`_cancelTimeout` here,
/// `FirebaseReviewRepository._submitTimeout` / `._deleteTimeout`) — those bound
/// small request/ack round-trips, this bounds a bulk transfer.
const Duration _kUploadDeadline = Duration(seconds: 60);

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

  /// A failed photo worth offering a Retry for: a transient failure (e.g. a
  /// network hiccup) whose retry can actually succeed. Null [failureKind]
  /// counts as transient (the default). Unprocessable failures are excluded —
  /// re-running compress on the same bytes only re-fails, so surfacing Retry
  /// for them is a dead button; the user must swap the photo instead.
  bool get hasTransientFailed => _photos.any((p) =>
      p.status == PhotoUploadStatus.failed &&
      p.failureKind != PhotoFailureKind.unprocessable);

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
    // The path is a pure derivation of (userId, localId) — both known right
    // here — so the entry carries it from birth rather than acquiring it on
    // upload success. Deriving it late was the whole 8f orphan: `removePhoto`
    // and `cancelAll` decide whether to delete by reading `storagePath`, and
    // for the entire processing + upload round-trip that field was still null,
    // so a removal mid-flight skipped the delete and left the blob behind.
    // Setting it now makes both guards correct by construction instead of by
    // timing. See [PhotoUploadState.storagePath] for the weakened contract.
    final storagePath = _storagePathFor(userId, localId);
    _photos.add(PhotoUploadState(
      localId: localId,
      originalFile: file,
      status: PhotoUploadStatus.processing,
      storagePath: storagePath,
    ));
    _notify();

    // Declared outside the try so the finally can tear both down on every exit
    // path — including the two early returns (A1, A3) below, which until now
    // leaked the progress subscription for the lifetime of the isolate.
    Timer? deadlineTimer;
    StreamSubscription<TaskSnapshot>? progressSub;

    try {
      final processed = await processImageForUpload(
        file,
        onCompressRetry: () => _analytics?.photoCompressRetry(),
      );
      _update(localId, (s) => s.copyWith(
            processedFile: processed,
            status: PhotoUploadStatus.uploading,
          ));

      // A1 — BANDWIDTH ONLY, not an orphan fix. Closes exactly one case: the
      // user picks a photo and removes it again before compression finishes,
      // which saves starting an upload nobody wants. It does NOTHING for the
      // abandon-during-upload case, whose window opens only after `putFile`
      // below has already been called: compression is a local native codec
      // measured in hundreds of milliseconds, while abandoning a slow upload
      // unfolds over seconds, so this check has long since passed by the time
      // the user reaches for back. The orphan class is closed by A3 after
      // `await task`, not here.
      //
      // No Storage delete on this path — `putFile` never ran, so there is no
      // blob and an object-not-found round-trip would be pure cost.
      if (!_isAlive(localId)) {
        // MANDATORY: nothing downstream will ever see this file again, so
        // skipping it would leak the compressed temp file to local disk.
        if (processed.path != file.path) {
          processed.delete().catchError((_) => processed);
        }
        return;
      }

      // Reuses the path derived at mint — exactly one derivation per photo, so
      // the ref written to can never drift from the one the delete guards read.
      final ref = _storage.ref(storagePath);
      final task = ref.putFile(
        processed,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      // Bound a stuck transfer by cancelling the task itself, NOT by racing
      // `await task` with a .timeout(). A .timeout() would leave the upload
      // running upstream and sever the A3 continuation below, so an abandon
      // after expiry would delete a blob that the still-running transfer then
      // publishes — exactly the orphan class A3 exists to close.
      //
      // VERIFIED ON iOS ONLY (firebase_storage 13.4.2 / platform_interface
      // 6.0.2 / firebase-ios-sdk 12.14.0, the latter read out-of-tree — it
      // links via SPM, not Pods). task.cancel() rejects `await task` promptly
      // with FirebaseException(plugin: 'firebase_storage', code: 'canceled'),
      // and a cancelled upload never publishes an object (single chunk, plus an
      // explicit X-Goog-Upload-Command: cancel), so no orphan cleanup is needed
      // on this path — the catch below only marks the tile failed.
      //
      // RESIDUAL RISK (iOS): if a cancelled upload ever leaves a tile stuck in
      // `uploading` past the deadline instead of flipping to `failed`, the
      // assumption that iOS never emits TaskState.canceled has broken. Revert
      // this deadline; do not patch around it.
      //
      // Gated to iOS because iOS is the only platform where cancel-on-deadline
      // was verified to terminate. On Android, method_channel_task.dart:77-85
      // handles TaskState.canceled by setting _didComplete and breaking WITHOUT
      // completing _completer, so `await task` would never resolve: the tile
      // would stay `uploading` forever and the user could not retry. That branch
      // is unreachable today only because nothing else in the app calls
      // cancel(). Leaving Android ungated would make it reachable, so Android
      // keeps its pre-existing unbounded-upload behaviour until the hang is
      // verified or fixed upstream.
      //
      // Racing `await task` against a synthetic failure instead (so the deadline
      // would work on both platforms) is NOT an option: it severs the A3
      // continuation, which is precisely the orphan class closed in commit 3-3.
      if (Platform.isIOS) {
        deadlineTimer = Timer(_kUploadDeadline, () {
          // Never bare `task.cancel()`. It returns a Future<bool> that can
          // reject (e.g. the benign race where the task has already finished),
          // and an unawaited rejection out of a timer callback is precisely the
          // unhandled zone error this commit exists to remove.
          unawaited(task.cancel().catchError((_) => false));
        });
      }

      progressSub = task.snapshotEvents.listen(
        (snap) {
          if (snap.totalBytes <= 0) return;
          _update(
            localId,
            (s) => s.copyWith(
              uploadProgress: snap.bytesTransferred / snap.totalBytes,
            ),
          );
        },
        // `await task` is the single source of truth for this upload's outcome;
        // the completer path in method_channel_task.dart delivers the identical
        // exception to the catch below. This handler exists only so the
        // duplicate stream-side error does not escape to the zone. Writing state
        // from here would double-classify the same failure.
        onError: (Object error, StackTrace stack) {
          debugPrint(
              'addPhoto: upload progress stream error for $storagePath: $error');
        },
      );

      await task;
      // Success path: the deadline is done governing, so retire it here rather
      // than leaving it armed across getDownloadURL. Timer.cancel() is
      // idempotent, so the finally's second call is free — and the finally must
      // keep it, because the throw path never reaches this line.
      //
      // Null-aware because the arming above is gated: off iOS the timer was
      // never created, so there is nothing to retire.
      deadlineTimer?.cancel();

      // A3 — the actual fix for the upload orphan class. Every other layer acts
      // on a prediction about ordering; this one acts after an accomplished
      // fact: `putFile` has resolved, so the blob EXISTS. If the entry is gone,
      // nothing will ever reference it — `completedStoragePaths` only collects
      // live entries, so it never reaches a review document, and both delete
      // guards (removePhoto, cancelAll) already ran and found either nothing or
      // a half-written object. Delete it here or it is orphaned forever.
      //
      // Placed BEFORE getDownloadURL deliberately. That also closes the case
      // where the upload succeeded but getDownloadURL would fail (both share
      // the catch below, which deletes nothing), and skips a pointless network
      // round-trip for a photo nobody wants.
      //
      // Runs correctly AFTER dispose(): `_disposed` is not consulted, `_photos`
      // survives disposal, and this path touches neither `_notify` nor
      // `_update` nor `photosNotifier` — all three are unsafe once the notifier
      // is disposed at :378, and `_update` would in any case bail at its own
      // `_disposed` guard before ever evaluating liveness.
      //
      // LOAD-BEARING INVARIANT, currently implicit elsewhere: an entry leaves
      // `_photos` ONLY via user removal, cancelAll (abandon), or retryPhoto —
      // NEVER via a successful submit, which reads the list without mutating
      // it. `_cleanupUploads`'s `if (_submitInitiated) return;` guard
      // (write_review_screen.dart:422) is what keeps cancelAll from running
      // once a write is handed to Firestore. So "entry absent" can never mean
      // "this URL already reached a review document." If that guard is ever
      // removed, this delete stops being cleanup and starts destroying the
      // photos of a review that is about to publish.
      if (!_isAlive(localId)) {
        try {
          await _storage.ref(storagePath).delete();
        } catch (e) {
          debugPrint(
              'addPhoto: failed to delete abandoned Storage photo at $storagePath: $e');
        }
        if (processed.path != file.path) {
          processed.delete().catchError((_) => processed);
        }
        return;
      }

      // A small request/ack round-trip, so it belongs to the 10s family, not to
      // [_kUploadDeadline]. Timing out here is safe for the orphan invariant:
      // the blob exists but the entry stays in `_photos` as `failed` carrying
      // the storagePath minted at :140, so retryPhoto and cancelAll both still
      // find and delete it.
      final url = await ref.getDownloadURL().timeout(const Duration(seconds: 10));

      // No `storagePath:` here — it was set at mint, and re-setting it would
      // imply completion is when the path becomes known. It never was.
      _update(localId, (s) => s.copyWith(
            status: PhotoUploadStatus.completed,
            downloadUrl: url,
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
    } finally {
      deadlineTimer?.cancel();
      try {
        await progressSub?.cancel();
      } catch (_) {
        // A failure to tear down the progress subscription must never replace
        // the real return value or the real exception travelling out of this
        // method.
      }
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
      // Update the list FIRST so the thumbnail disappears immediately — this is
      // a user-interactive path (X button), so we never block the UI on the
      // network delete below.
      _photos.removeAt(index);
      _notify();
      if (photo.storagePath != null) {
        try {
          await _storage.ref(photo.storagePath!).delete();
        } catch (e) {
          debugPrint(
              'removePhoto: failed to delete Storage photo at ${photo.storagePath}: $e');
        }
      }
      final processed = photo.processedFile;
      if (processed != null && processed.path != photo.originalFile.path) {
        processed.delete().catchError((_) => processed);
      }
      return;
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

    // A retry mints a NEW localId and therefore a NEW path, so the old one
    // becomes unreachable the instant this entry is discarded. That matters
    // because `putFile` and `getDownloadURL` share one catch: a failure at the
    // getDownloadURL stage means the upload ALREADY succeeded and a blob is
    // sitting at the old path. Drop it here or nothing ever will.
    //
    // Safe unconditionally: a failed photo is by definition absent from every
    // Firestore document — the review has not been written, and
    // `completedStoragePaths` only ever collects completed entries — so no doc
    // can reference this blob. Existing (edit-mode) photos never reach here;
    // they load as completed and the status guard above returns first.
    final oldPath = photo.storagePath;
    if (oldPath != null && !photo.isExisting) {
      // Fire-and-forget: retry is user-interactive, so the re-upload below must
      // not wait on cleanup of a blob the user has already stopped caring about.
      unawaited(() async {
        try {
          await _storage.ref(oldPath).delete();
        } catch (e) {
          debugPrint(
              'retryPhoto: failed to delete Storage photo at $oldPath: $e');
        }
      }());
    }

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

  /// Bound on the whole abandon-cleanup phase.
  ///
  /// Mirrors `FirebaseReviewRepository._deleteTimeout`: on a stalled
  /// network the Storage SDK keeps retrying for ~2 minutes, which left the
  /// caller's back tap dead for that long with nothing rendered.
  ///
  /// On timeout we return and let the caller pop anyway. That is deliberate and
  /// is NOT a cleanup guarantee being dropped: the deletes stay queued in the
  /// SDK and still land on reconnect, which on this path — the user abandoning
  /// a draft — is exactly what they asked for. Anything that never lands is
  /// covered by the tracked v1.1 server-side reconciliation sweep. Blocking the
  /// user in order to guarantee cleanup is the bug being fixed, not the
  /// contract.
  static const Duration _cancelTimeout = Duration(seconds: 10);

  /// Abandon: delete every uploaded (non-existing) photo from Storage and
  /// clear local temp files. Existing photos are left untouched.
  ///
  /// MUST NOT be called once a review write has been handed to Firestore — see
  /// `_WriteReviewScreenState._submitInitiated`. Deleting the blobs of a write
  /// that already committed (or that commits later from the offline queue)
  /// publishes a review whose photoUrls 404.
  Future<void> cancelAll() async {
    // Snapshot the doomed entries, then clear the list BEFORE issuing a single
    // delete. The ordering is load-bearing, not cosmetic.
    //
    // The post-upload check in [addPhoto] treats "absent from `_photos`" as
    // "abandoned — delete the blob". That contract requires there to be NO
    // interval in which an entry is still present but already doomed. Clearing
    // after the awaits created exactly such an interval, up to [_cancelTimeout]
    // wide: an upload resolving inside it found itself still "alive", skipped
    // its own cleanup, and then had its `_update` no-op against the list this
    // method had since cleared — leaving the blob with nothing referencing it.
    // That is the orphan the check exists to prevent.
    //
    // Any future edit that moves the clear back below the awaits silently
    // reopens it.
    final doomed = _photos.where((p) => !p.isExisting).toList();

    // Repaints the strip empty before the network work rather than after. Safe:
    // the only caller (`_WriteReviewScreenState._cleanupUploads`) has already
    // set `_closing`, which puts the form behind an AbsorbPointer and holds
    // `PopScope.canPop` false, and it pops the screen the moment this returns.
    _photos.clear();
    _notify();

    // Collect each Storage delete so we can await them together — they should
    // resolve BEFORE this returns, since the caller pops the screen right
    // after. Bounded by [_cancelTimeout] so a stalled network can't hold the
    // pop hostage.
    final storageDeletes = <Future<void>>[];
    for (final photo in doomed) {
      if (photo.storagePath != null) {
        storageDeletes.add(() async {
          try {
            await _storage.ref(photo.storagePath!).delete();
          } catch (e) {
            // One failure must not abort the others — log and move on.
            debugPrint(
                'cancelAll: failed to delete Storage photo at ${photo.storagePath}: $e');
          }
        }());
      }
      final processed = photo.processedFile;
      if (processed != null && processed.path != photo.originalFile.path) {
        // Local temp file — not orphan-relevant, so don't block on it.
        processed.delete().catchError((_) => processed);
      }
    }
    try {
      await Future.wait(storageDeletes).timeout(_cancelTimeout);
    } on TimeoutException {
      // Proceed regardless — see [_cancelTimeout]. The queued deletes are not
      // cancelled by giving up on the wait; they still land on reconnect.
      debugPrint('cancelAll: Storage deletes still pending after '
          '$_cancelTimeout; releasing the caller.');
    }
  }

  /// Whether [localId] is still in the list — i.e. the user has not removed it
  /// and no abandon-cleanup has cleared it.
  ///
  /// Deliberately does NOT consult `_disposed`, unlike [_update]. That is the
  /// entire point: after `dispose()` the entry is gone and its blob still needs
  /// deleting, so an in-flight upload's completion must be able to ask this
  /// question and get a truthful answer on a dead manager. `_photos` outlives
  /// disposal (see [dispose]); only the notifier does not.
  bool _isAlive(String localId) =>
      _photos.indexWhere((p) => p.localId == localId) >= 0;

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
