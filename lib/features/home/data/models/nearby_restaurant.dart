/// Domain model for a restaurant returned by Google Places (New) Nearby Search.
///
/// Only the fields the Home feed actually renders are kept — the API can
/// return much more (open hours, types, etc.) but pulling them in costs
/// money per field-mask request and clutters the model.
class NearbyRestaurant {
  const NearbyRestaurant({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.rating,
    this.userRatingCount,
    this.priceLevel,
    this.photoName,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double? rating;
  final int? userRatingCount;
  final PriceLevel? priceLevel;

  /// Resource name of the first photo (e.g. `places/abc/photos/xyz`).
  /// Convert to an image URL via [PlacesApiDatasource.photoUrl].
  final String? photoName;

  factory NearbyRestaurant.fromJson(Map<String, dynamic> json) {
    final displayName = json['displayName'] as Map<String, dynamic>?;
    final location = json['location'] as Map<String, dynamic>?;
    final photos = json['photos'] as List?;
    final firstPhoto = (photos != null && photos.isNotEmpty)
        ? photos.first as Map<String, dynamic>
        : null;

    return NearbyRestaurant(
      id: json['id'] as String? ?? '',
      name: (displayName?['text'] as String?) ?? '',
      latitude: (location?['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (location?['longitude'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingCount: json['userRatingCount'] as int?,
      priceLevel: PriceLevel.fromApi(json['priceLevel'] as String?),
      photoName: firstPhoto?['name'] as String?,
    );
  }
}

/// Maps Google's PRICE_LEVEL_* enum to the dollar-sign string we render.
enum PriceLevel {
  inexpensive(r'$'),
  moderate(r'$$'),
  expensive(r'$$$'),
  veryExpensive(r'$$$$');

  const PriceLevel(this.display);
  final String display;

  static PriceLevel? fromApi(String? value) {
    switch (value) {
      case 'PRICE_LEVEL_INEXPENSIVE':
        return PriceLevel.inexpensive;
      case 'PRICE_LEVEL_MODERATE':
        return PriceLevel.moderate;
      case 'PRICE_LEVEL_EXPENSIVE':
        return PriceLevel.expensive;
      case 'PRICE_LEVEL_VERY_EXPENSIVE':
        return PriceLevel.veryExpensive;
      default:
        return null;
    }
  }
}
