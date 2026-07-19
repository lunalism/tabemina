import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../../domain/entities/report_reason.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/review_repository.dart';

/// Firestore + Storage implementation of [ReviewRepository].
///
/// Photos are pre-uploaded to Storage by the write-review flow (see
/// PhotoUploadManager), so submit/update are pure Firestore writes that
/// persist the already-resolved photo URLs alongside their Storage object
/// paths. The stored paths let [deleteReview] remove the exact blobs — the
/// pre-upload refactor moved photos to `reviews/{userId}/{localId}.jpg`, a
/// prefix shared across a user's reviews, so the old folder-wide delete no
/// longer works.
class FirebaseReviewRepository implements ReviewRepository {
  FirebaseReviewRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _firestore.collection('reviews');

  @override
  String newReviewId() => _reviews.doc().id;

  @override
  Future<bool> reviewExists(String reviewId) async {
    // Read is public per the Firestore rules, so this probe is always allowed
    // — unlike a re-set(), which would hit the owner-only UPDATE path.
    final snap = await _reviews.doc(reviewId).get();
    return snap.exists;
  }

  @override
  Future<ReviewEntity> submitReview(
    String reviewId,
    ReviewDraftData draft,
    List<String> photoUrls,
    List<String> photoStoragePaths,
  ) async {
    // The id is minted by [newReviewId] and passed in so a retry re-targets
    // the same doc. This is always a create (set on a not-yet-existing id);
    // callers gate retries on [reviewExists] and never re-set an existing doc.
    final docRef = _reviews.doc(reviewId);
    final now = DateTime.now();
    final data = <String, dynamic>{
      'reviewId': reviewId,
      'userId': draft.userId,
      'userName': draft.userName,
      'userPhotoUrl': draft.userPhotoUrl,
      'placeId': draft.placeId,
      'placeName': draft.placeName,
      'placeAddress': draft.placeAddress,
      'placeLat': draft.placeLat,
      'placeLng': draft.placeLng,
      'rating': draft.rating,
      'comment': draft.comment,
      'moodTags': draft.moodTags,
      'priceTags': draft.priceTags,
      'photoUrls': photoUrls,
      'photoStoragePaths': photoStoragePaths,
      // Moderation fields — written explicitly so new reviews always carry
      // them (older docs may lack them; reads default to 0 / false).
      'reportCount': 0,
      'isHidden': false,
      'language': draft.language,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(data);

    return ReviewEntity(
      reviewId: reviewId,
      userId: draft.userId,
      userName: draft.userName,
      userPhotoUrl: draft.userPhotoUrl,
      placeId: draft.placeId,
      placeName: draft.placeName,
      placeAddress: draft.placeAddress,
      placeLat: draft.placeLat,
      placeLng: draft.placeLng,
      rating: draft.rating,
      comment: draft.comment,
      moodTags: draft.moodTags,
      priceTags: draft.priceTags,
      photoUrls: photoUrls,
      photoStoragePaths: photoStoragePaths,
      language: draft.language,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<ReviewEntity> updateReview(
    ReviewEntity review,
    List<String> photoUrls,
    List<String> photoStoragePaths,
    List<String> removedPhotoUrls,
    List<String> removedStoragePaths,
  ) async {
    // Delete removed photos from Storage (best-effort — a failed delete
    // leaves an orphan blob but doesn't block the edit). New photos are
    // already uploaded by the pre-upload flow, so [photoUrls] is final.
    //
    // Prefer deleting by Storage path (exact ref, no URL parsing). Fall back
    // to refFromURL for photos that predate path tracking, where the path
    // isn't known. Both are guarded — a removed photo carried in both lists
    // simply 404s on the second attempt, which we ignore.
    for (final path in removedStoragePaths) {
      try {
        await _storage.ref(path).delete();
      } on FirebaseException {
        // Already gone / no permission — ignore.
      }
    }
    for (final url in removedPhotoUrls) {
      try {
        await _storage.refFromURL(url).delete();
      } on FirebaseException {
        // Already gone (path delete above handled it) / no permission.
      }
    }

    await _reviews.doc(review.reviewId).update({
      'rating': review.rating,
      'comment': review.comment,
      'moodTags': review.moodTags,
      'priceTags': review.priceTags,
      'photoUrls': photoUrls,
      'photoStoragePaths': photoStoragePaths,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ReviewEntity(
      reviewId: review.reviewId,
      userId: review.userId,
      userName: review.userName,
      userPhotoUrl: review.userPhotoUrl,
      placeId: review.placeId,
      placeName: review.placeName,
      placeAddress: review.placeAddress,
      placeLat: review.placeLat,
      placeLng: review.placeLng,
      rating: review.rating,
      comment: review.comment,
      moodTags: review.moodTags,
      priceTags: review.priceTags,
      photoUrls: photoUrls,
      photoStoragePaths: photoStoragePaths,
      language: review.language,
      createdAt: review.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<ReviewEntity>> getReviewsForPlace(String placeId) async {
    final snap = await _reviews
        .where('placeId', isEqualTo: placeId)
        .orderBy('createdAt', descending: true)
        .get();
    return _visible(snap.docs);
  }

  @override
  Future<DateTime?> getLastReviewTimeForPlace(
    String userId,
    String placeId,
  ) async {
    // Two equality filters only — no orderBy — so this is served by
    // automatic single-field indexes and needs no composite index. A user
    // has at most a handful of reviews per place, so taking the max
    // createdAt client-side is cheap.
    final snap = await _reviews
        .where('userId', isEqualTo: userId)
        .where('placeId', isEqualTo: placeId)
        .get();
    DateTime? latest;
    for (final doc in snap.docs) {
      final ts = doc.data()['createdAt'];
      if (ts is Timestamp) {
        final dt = ts.toDate();
        if (latest == null || dt.isAfter(latest)) latest = dt;
      }
    }
    return latest;
  }

  @override
  Future<bool> canReviewPlace(String userId, String placeId) async {
    final last = await getLastReviewTimeForPlace(userId, placeId);
    if (last == null) return true;
    return DateTime.now().difference(last) >= const Duration(hours: 24);
  }

  @override
  Future<List<ReviewEntity>> getReviewsByUser(String userId) async {
    final snap = await _reviews
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => _fromDoc(d.id, d.data())).toList();
  }

  @override
  Future<List<ReviewEntity>> getLatestReviews({int limit = 10}) async {
    // Over-fetch then filter client-side so a few hidden reviews don't shrink
    // the home feed below `limit`. Client-side filtering (not a
    // where('isHidden', false) query) is deliberate — that query would also
    // drop older docs that lack the field. See [_visible].
    final snap = await _reviews
        .orderBy('createdAt', descending: true)
        .limit(limit * 2)
        .get();
    // The default serverAndCache get() doesn't throw when offline — it falls
    // back to the cache, which on a fresh install is empty. Left alone that
    // renders as a fake "no reviews yet"; surface it as a failure instead so
    // the feed shows its error + retry state. A warm cache (docs present)
    // still serves stale data offline, which is desired.
    if (snap.metadata.isFromCache && snap.docs.isEmpty) {
      throw const ReviewsUnavailableException();
    }
    return _visible(snap.docs).take(limit).toList();
  }

  @override
  Stream<List<ReviewEntity>> watchReviewsForPlace(String placeId) {
    // includeMetadataChanges so the cache→server transition emits even when
    // the docs are identical (e.g. a place with zero reviews): without it the
    // error event below would never be superseded once the server confirms
    // the empty result.
    return _reviews
        .where('placeId', isEqualTo: placeId)
        .orderBy('createdAt', descending: true)
        .snapshots(includeMetadataChanges: true)
        .map((s) {
      // Same failure mode as getLatestReviews: offline, snapshots() serves
      // the cache, which on a fresh install is empty. Left alone that renders
      // as a fake "no reviews yet"; surface it as a failure instead so the
      // detail page shows its error + retry state. Throwing inside map()
      // emits an error EVENT without cancelling the subscription — when
      // connectivity returns the next server snapshot still flows through
      // and replaces the error. A warm cache (docs present) still serves
      // stale data offline, which is desired.
      if (s.metadata.isFromCache && s.docs.isEmpty) {
        throw const ReviewsUnavailableException();
      }
      return _visible(s.docs);
    });
  }

  /// Per-object bound on each Storage delete/list call in [deleteReview].
  /// The Storage SDK's own retry window is ~2 minutes, which offline left
  /// the delete spinner up until reconnect. Per-object (not wrapping the
  /// whole phase) so a multi-photo review on a slow-but-working network
  /// isn't failed while every individual call is succeeding; offline the
  /// FIRST call times out, and a [TimeoutException] aborts the whole
  /// operation before the doc delete (see below), so the failure surfaces
  /// in ~10s either way.
  static const Duration _storageDeleteTimeout = Duration(seconds: 10);

  @override
  Future<void> deleteReview(String reviewId) async {
    // Read the doc first to recover the exact Storage paths — the
    // pre-upload layout (`reviews/{userId}/{localId}.jpg`) shares a prefix
    // across a user's reviews, so there's no per-review folder to wipe.
    final docRef = _reviews.doc(reviewId);
    final snap = await docRef.get();
    final data = snap.data();

    // TimeoutException propagates out of both branches below ON PURPOSE:
    // a doc delete after skipped Storage deletes would orphan the photos
    // permanently (the B-5 orphan pattern), so timeout = the whole delete
    // fails, the review stays, and the user retries online. No rollback for
    // objects already deleted before the timeout — a retried delete
    // re-attempts idempotently (missing objects fall into the swallowed
    // object-not-found case), and the server-side reconciliation backlog
    // item covers any residue.
    if (data != null) {
      final storagePaths = _stringList(data['photoStoragePaths']);
      if (storagePaths.isNotEmpty) {
        for (final path in storagePaths) {
          try {
            await _storage.ref(path).delete().timeout(_storageDeleteTimeout);
          } on TimeoutException {
            rethrow;
          } catch (e) {
            // Photo may already be gone — ignore so the doc still deletes.
            debugPrint('Failed to delete photo at $path: $e');
          }
        }
      } else {
        // Backwards compatibility: reviews created before path tracking
        // used the old `reviews/{reviewId}/` folder layout. Try the
        // folder-wide cleanup; old blobs may already be orphaned, which is
        // acceptable.
        try {
          final listing = await _storage
              .ref('reviews/$reviewId')
              .listAll()
              .timeout(_storageDeleteTimeout);
          for (final item in listing.items) {
            await item.delete().timeout(_storageDeleteTimeout);
          }
        } on TimeoutException {
          rethrow;
        } catch (e) {
          debugPrint('Old-style photo cleanup failed: $e');
        }
      }
    }

    // Delete the document last — reached only when the Storage phase ran to
    // completion (non-timeout Storage errors are swallowed above, timeouts
    // abort). Offline queueing of THIS delete (it completes on reconnect)
    // is fine — by now the photos are gone.
    await docRef.delete();
  }

  @override
  Future<ReportOutcome> reportReview({
    required String reviewId,
    required String reporterUserId,
    required ReportReason reason,
  }) {
    // Deterministic report doc id ({reviewId}_{uid}) guarantees one report
    // per user per review, so reportCount can never be double-incremented by
    // the same user. The whole thing runs in one transaction so a duplicate
    // tap (or a race) can't slip a second increment through.
    final reportRef =
        _firestore.collection('reports').doc('${reviewId}_$reporterUserId');
    final reviewRef = _reviews.doc(reviewId);

    return _firestore.runTransaction<ReportOutcome>((txn) async {
      // Firestore requires all reads before any writes.
      final reportSnap = await txn.get(reportRef);
      if (reportSnap.exists) {
        // Already reported by this user — abort without touching the count.
        return ReportOutcome.alreadyReported;
      }
      final reviewSnap = await txn.get(reviewRef);
      if (!reviewSnap.exists) {
        // Review was deleted between display and report — nothing to do.
        return ReportOutcome.alreadyReported;
      }
      final data = reviewSnap.data()!;
      final currentCount = (data['reportCount'] as num?)?.toInt() ?? 0;
      final nextCount = currentCount + 1;

      // Reporter identity lives only in the report doc (never surfaced in
      // any UI). reportedUserId / restaurantPlaceId come from the review doc
      // so the client can't spoof them.
      txn.set(reportRef, {
        'reviewId': reviewId,
        'reportedUserId': data['userId'] ?? '',
        'reporterUserId': reporterUserId,
        'reason': reason.wireValue,
        'restaurantPlaceId': data['placeId'] ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      txn.update(reviewRef, {
        'reportCount': nextCount,
        if (nextCount >= kReportThreshold) 'isHidden': true,
      });
      return ReportOutcome.submitted;
    });
  }

  /// Map docs to entities and drop the hidden ones. Done in Dart — NOT as a
  /// `where('isHidden', isEqualTo: false)` query — so older docs that lack
  /// the field (null, not false) still show. At launch volume this is cheap
  /// and correct for mixed old/new data.
  List<ReviewEntity> _visible(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return [
      for (final d in docs)
        if (!(d.data()['isHidden'] as bool? ?? false)) _fromDoc(d.id, d.data()),
    ];
  }

  ReviewEntity _fromDoc(String docId, Map<String, dynamic> data) {
    return ReviewEntity(
      reviewId: data['reviewId'] as String? ?? docId,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userPhotoUrl: data['userPhotoUrl'] as String?,
      placeId: data['placeId'] as String? ?? '',
      placeName: data['placeName'] as String? ?? '',
      placeAddress: data['placeAddress'] as String?,
      placeLat: (data['placeLat'] as num?)?.toDouble(),
      placeLng: (data['placeLng'] as num?)?.toDouble(),
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      comment: data['comment'] as String? ?? '',
      moodTags: _stringList(data['moodTags']),
      priceTags: _stringList(data['priceTags']),
      photoUrls: _stringList(data['photoUrls']),
      photoStoragePaths: _stringList(data['photoStoragePaths']),
      reportCount: (data['reportCount'] as num?)?.toInt() ?? 0,
      isHidden: data['isHidden'] as bool? ?? false,
      isAuthorDeleted: data['isAuthorDeleted'] as bool? ?? false,
      language: data['language'] as String? ?? 'en',
      createdAt: _timestampOrNow(data['createdAt']),
      updatedAt: _timestampOrNow(data['updatedAt']),
    );
  }

  List<String> _stringList(dynamic v) {
    if (v is List) return [for (final x in v) if (x is String) x];
    return const [];
  }

  /// Firestore returns `null` for `serverTimestamp` fields on the local-write
  /// echo (before the round-trip resolves), so callers might see a freshly
  /// posted review for a few hundred ms with no createdAt. Falling back to
  /// "now" keeps the UI sortable in that window.
  DateTime _timestampOrNow(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return DateTime.now();
  }
}
