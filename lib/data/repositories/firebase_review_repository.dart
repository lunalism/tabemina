import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/review_repository.dart';

/// Firestore + Storage implementation of [ReviewRepository].
///
/// Photos are pre-uploaded to Storage by the write-review flow (see
/// PhotoUploadManager), so submit/update are pure Firestore writes that
/// just persist the already-resolved photo URLs. Deleting a review still
/// clears its Storage folder.
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
  Future<ReviewEntity> submitReview(
    ReviewDraftData draft,
    List<String> photoUrls,
  ) async {
    final docRef = _reviews.doc();
    final reviewId = docRef.id;
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
      language: draft.language,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<ReviewEntity> updateReview(
    ReviewEntity review,
    List<String> photoUrls,
    List<String> removedPhotoUrls,
  ) async {
    // Delete removed photos from Storage (best-effort — a failed delete
    // leaves an orphan blob but doesn't block the edit). New photos are
    // already uploaded by the pre-upload flow, so [photoUrls] is final.
    for (final url in removedPhotoUrls) {
      try {
        await _storage.refFromURL(url).delete();
      } on FirebaseException {
        // Already gone / no permission — ignore.
      }
    }

    await _reviews.doc(review.reviewId).update({
      'rating': review.rating,
      'comment': review.comment,
      'moodTags': review.moodTags,
      'priceTags': review.priceTags,
      'photoUrls': photoUrls,
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
    return snap.docs.map((d) => _fromDoc(d.id, d.data())).toList();
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
    final snap = await _reviews
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => _fromDoc(d.id, d.data())).toList();
  }

  @override
  Stream<List<ReviewEntity>> watchReviewsForPlace(String placeId) {
    return _reviews
        .where('placeId', isEqualTo: placeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => _fromDoc(d.id, d.data())).toList());
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    // Delete the document first — even if Storage delete fails, the orphan
    // blobs won't be referenced anywhere. Doing it the other way risks
    // showing a broken card if the Storage half succeeds but Firestore
    // fails.
    await _reviews.doc(reviewId).delete();
    final folder = _storage.ref('reviews/$reviewId');
    try {
      final listing = await folder.listAll();
      await Future.wait(listing.items.map((r) => r.delete()));
    } on FirebaseException {
      // No-op — the folder may not exist (review had no photos), or the
      // user lacks delete permission for an older review. Either way the
      // user already sees the review as gone.
    }
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
