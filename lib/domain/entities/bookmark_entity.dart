import 'package:flutter/foundation.dart';

/// Domain-layer bookmark — provider-agnostic.
///
/// One saved restaurant. We persist enough fields to render the Bookmarks
/// card without re-hitting Google Places, regardless of whether the storage
/// backend is Firestore (logged-in users) or SharedPreferences (guests).
@immutable
class BookmarkEntity {
  const BookmarkEntity({
    required this.placeId,
    required this.placeName,
    required this.savedAt,
    this.placeAddress,
    this.placeLat,
    this.placeLng,
    this.placePhotoUrl,
    this.placeRating,
    this.userRatingCount,
    this.priceLevel,
    this.primaryType,
  });

  final String placeId;
  final String placeName;
  final String? placeAddress;
  final double? placeLat;
  final double? placeLng;

  /// Fully-formed photo URL (Google Places photo with API key baked in)
  /// rather than the raw `places/.../photos/...` reference, so cards can
  /// render without re-importing the datasource just for the URL builder.
  final String? placePhotoUrl;
  final double? placeRating;
  final int? userRatingCount;
  final String? priceLevel;
  final String? primaryType;
  final DateTime savedAt;
}
