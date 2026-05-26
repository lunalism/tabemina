import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/review_repository.dart';

/// Firestore + Storage implementation of [ReviewRepository].
///
/// Documents live in the top-level `reviews` collection; their photos live
/// in Storage under `reviews/{reviewId}/{filename}` so the document and its
/// attachments share a key and can be cleaned up together on delete.
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
    List<File> photos,
  ) async {
    // Reserve the doc up-front so we can use its id as the photo folder
    // name. This keeps photo → review mapping deterministic even if the
    // Firestore write fails (we can clean up by review id later).
    final docRef = _reviews.doc();
    final reviewId = docRef.id;

    final photoUrls = await _uploadPhotos(reviewId, photos);

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
  Future<List<ReviewEntity>> getReviewsForPlace(String placeId) async {
    final snap = await _reviews
        .where('placeId', isEqualTo: placeId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => _fromDoc(d.id, d.data())).toList();
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

  Future<List<String>> _uploadPhotos(String reviewId, List<File> photos) async {
    final urls = <String>[];
    for (var i = 0; i < photos.length; i++) {
      final file = photos[i];
      final ext = _extensionOf(file.path);
      final name = '${DateTime.now().millisecondsSinceEpoch}_$i$ext';
      final ref = _storage.ref('reviews/$reviewId/$name');
      // image_picker already downsamples to maxWidth=1200 / quality=82, so
      // most photos land under 1MB. A heavy server-side compress pass
      // would need a native lib and isn't worth the build complexity for
      // v1 — the existing picker config keeps payloads reasonable.
      await ref.putFile(file, _metadataFor(ext));
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  String _extensionOf(String path) {
    final slash = path.lastIndexOf('/');
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot < slash) return '.jpg';
    return path.substring(dot).toLowerCase();
  }

  SettableMetadata? _metadataFor(String ext) {
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return SettableMetadata(contentType: 'image/jpeg');
      case '.png':
        return SettableMetadata(contentType: 'image/png');
      case '.webp':
        return SettableMetadata(contentType: 'image/webp');
      default:
        return null;
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
