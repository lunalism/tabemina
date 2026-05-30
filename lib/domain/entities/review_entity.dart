import 'package:flutter/foundation.dart';

/// Domain-layer review — provider-agnostic.
///
/// Field shape mirrors the Firestore `reviews/{reviewId}` document, but the
/// domain has no Firebase imports so other backends could populate the same
/// entity.
@immutable
class ReviewEntity {
  const ReviewEntity({
    required this.reviewId,
    required this.userId,
    required this.userName,
    required this.placeId,
    required this.placeName,
    required this.rating,
    required this.comment,
    required this.moodTags,
    required this.priceTags,
    required this.photoUrls,
    required this.language,
    required this.createdAt,
    required this.updatedAt,
    this.userPhotoUrl,
    this.placeAddress,
    this.placeLat,
    this.placeLng,
    this.photoStoragePaths = const [],
    this.reportCount = 0,
    this.isHidden = false,
  });

  final String reviewId;
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
  final List<String> photoUrls;

  /// Firebase Storage object paths for [photoUrls], persisted so a delete can
  /// remove the exact blobs. Empty for reviews created before storage-path
  /// tracking landed (their photos may orphan on delete — see
  /// FirebaseReviewRepository.deleteReview's fallback).
  final List<String> photoStoragePaths;
  final String language;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// How many times this review has been reported. Persisted on the doc and
  /// incremented atomically in the report transaction. Missing on older docs
  /// (treated as 0).
  final int reportCount;

  /// Whether the review is hidden from public listings (auto-set once
  /// [reportCount] crosses kReportThreshold). Missing on older docs (treated
  /// as false → visible). Filtered out client-side everywhere except the
  /// author's own My Page list, where it's shown with an "Under review" tag.
  final bool isHidden;
}
