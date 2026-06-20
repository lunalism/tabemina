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

  /// Bare Places photo *resource name* (e.g. `places/.../photos/...`). The
  /// display URL is rebuilt with the current API key at render time so a key
  /// rotation can't strand a dead `?key=` in saved bookmarks. Legacy bookmarks
  /// may still hold a full media URL here; the render path tolerates both.
  /// (Field name kept as `placePhotoUrl` to avoid a Firestore schema migration.)
  final String? placePhotoUrl;
  final double? placeRating;
  final int? userRatingCount;
  final String? priceLevel;
  final String? primaryType;
  final DateTime savedAt;
}
