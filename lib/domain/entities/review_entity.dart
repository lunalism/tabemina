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
  final String language;
  final DateTime createdAt;
  final DateTime updatedAt;
}
