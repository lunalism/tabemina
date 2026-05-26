import 'dart:io';

import '../entities/review_entity.dart';

/// A new review the user just composed in the write-review form. The
/// repository is responsible for assigning [reviewId], [createdAt],
/// [updatedAt], and the resolved photo URLs after upload.
class ReviewDraftData {
  const ReviewDraftData({
    required this.userId,
    required this.userName,
    required this.placeId,
    required this.placeName,
    required this.rating,
    required this.comment,
    required this.moodTags,
    required this.priceTags,
    required this.language,
    this.userPhotoUrl,
    this.placeAddress,
    this.placeLat,
    this.placeLng,
  });

  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String placeId;
  final String placeName;
  final String? placeAddress;
  final double? placeLat;
  final double? placeLng;
  final double rating;
  final String comment;
  final List<String> moodTags;
  final List<String> priceTags;
  final String language;
}

/// Abstract review-storage contract.
///
/// The presentation layer talks to this interface only — never to Firestore
/// or Storage. Swapping backends means writing a new implementation, not
/// changing any screen code.
abstract class ReviewRepository {
  /// Upload [photos] to backing storage, then write the resulting review
  /// document. Returns the persisted entity (with [reviewId], timestamps,
  /// and final photo URLs).
  Future<ReviewEntity> submitReview(
    ReviewDraftData draft,
    List<File> photos,
  );

  Future<List<ReviewEntity>> getReviewsForPlace(String placeId);

  Future<List<ReviewEntity>> getReviewsByUser(String userId);

  /// One-shot read of the newest reviews across all places (Home feed).
  Future<List<ReviewEntity>> getLatestReviews({int limit = 10});

  Stream<List<ReviewEntity>> watchReviewsForPlace(String placeId);

  Future<void> deleteReview(String reviewId);
}
