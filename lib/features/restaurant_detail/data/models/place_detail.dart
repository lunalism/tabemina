/// Domain model for a single place returned by Google Places (New) Place
/// Details.
///
/// Only the fields the detail screen renders are pulled in — the API can
/// return ~50 more, but each one costs in the field mask and increases
/// payload weight. Add new fields here alongside the matching slot in the
/// FieldMask header.
class PlaceDetail {
  const PlaceDetail({
    required this.id,
    required this.displayName,
    this.formattedAddress,
    this.phoneNumber,
    this.internationalPhoneNumber,
    this.websiteUri,
    this.rating,
    this.userRatingCount,
    this.priceLevel,
    this.photoNames = const [],
    this.editorialSummary,
    this.googleMapsUri,
    this.lat,
    this.lng,
    this.types = const [],
    this.primaryType,
    this.businessStatus,
    this.currentOpeningHours,
  });

  final String id;
  final String displayName;
  final String? formattedAddress;
  final String? phoneNumber;
  final String? internationalPhoneNumber;
  final String? websiteUri;
  final double? rating;
  final int? userRatingCount;

  /// Raw Google enum, e.g. `PRICE_LEVEL_MODERATE`. Render via
  /// [formatYenPriceLevel].
  final String? priceLevel;

  /// Photo resource names (e.g. `places/abc/photos/xyz`). Convert to image
  /// URLs via [PlaceDetailRemoteDatasource.photoUrl].
  final List<String> photoNames;
  final String? editorialSummary;
  final String? googleMapsUri;
  final double? lat;
  final double? lng;
  final List<String> types;
  final String? primaryType;
  final String? businessStatus;
  final OpeningHours? currentOpeningHours;

  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    final displayName = json['displayName'] as Map<String, dynamic>?;
    final editorialSummary =
        json['editorialSummary'] as Map<String, dynamic>?;
    final location = json['location'] as Map<String, dynamic>?;
    final photos = (json['photos'] as List?) ?? const [];
    final types = (json['types'] as List?) ?? const [];
    final hours = json['currentOpeningHours'] as Map<String, dynamic>? ??
        json['regularOpeningHours'] as Map<String, dynamic>?;

    return PlaceDetail(
      id: json['id'] as String? ?? '',
      displayName: (displayName?['text'] as String?) ?? '',
      formattedAddress: json['formattedAddress'] as String?,
      phoneNumber: json['nationalPhoneNumber'] as String?,
      internationalPhoneNumber: json['internationalPhoneNumber'] as String?,
      websiteUri: json['websiteUri'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingCount: json['userRatingCount'] as int?,
      priceLevel: json['priceLevel'] as String?,
      photoNames: [
        for (final p in photos)
          if (p is Map<String, dynamic> && p['name'] is String)
            p['name'] as String,
      ],
      editorialSummary: editorialSummary?['text'] as String?,
      googleMapsUri: json['googleMapsUri'] as String?,
      lat: (location?['latitude'] as num?)?.toDouble(),
      lng: (location?['longitude'] as num?)?.toDouble(),
      types: [for (final t in types) if (t is String) t],
      primaryType: json['primaryType'] as String?,
      businessStatus: json['businessStatus'] as String?,
      currentOpeningHours: hours == null ? null : OpeningHours.fromJson(hours),
    );
  }
}

/// Open hours snapshot — `openNow` is the live computed flag, and
/// `weekdayDescriptions` is the 7-line human string the API renders in the
/// caller's locale.
class OpeningHours {
  const OpeningHours({
    required this.openNow,
    required this.weekdayDescriptions,
  });

  final bool openNow;
  final List<String> weekdayDescriptions;

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    final descriptions = (json['weekdayDescriptions'] as List?) ?? const [];
    return OpeningHours(
      openNow: json['openNow'] as bool? ?? false,
      weekdayDescriptions: [
        for (final d in descriptions) if (d is String) d,
      ],
    );
  }
}

/// Map Google's PRICE_LEVEL_* enum to a yen-sign string for the detail
/// header. Returns `null` so callers can hide the segment when the API
/// doesn't know the price level (rather than render a misleading empty
/// string).
String? formatYenPriceLevel(String? priceLevel) {
  switch (priceLevel) {
    case 'PRICE_LEVEL_INEXPENSIVE':
      return '¥';
    case 'PRICE_LEVEL_MODERATE':
      return '¥¥';
    case 'PRICE_LEVEL_EXPENSIVE':
      return '¥¥¥';
    case 'PRICE_LEVEL_VERY_EXPENSIVE':
      return '¥¥¥¥';
    default:
      return null;
  }
}

/// `japanese_restaurant` → `Japanese restaurant`. Used for the category
/// line under the restaurant name on the detail header.
String formatPrimaryType(String raw) {
  if (raw.isEmpty) return '';
  final words = raw.split('_');
  final first = words.first;
  final capitalized = first.isEmpty
      ? ''
      : '${first[0].toUpperCase()}${first.substring(1)}';
  return [capitalized, ...words.skip(1)].join(' ');
}
