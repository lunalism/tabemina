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
    this.reviews = const [],
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

  /// Up to 5 live Google reviews piggybacked on the same Place Details call.
  ///
  /// COMPLIANCE: this list is held in memory only for the lifetime of the open
  /// detail screen and is NEVER cached or persisted (no Firestore / DB / prefs)
  /// per Google Places policy. It is intentionally excluded from any stored
  /// representation (e.g. the bookmark entity).
  final List<GoogleReview> reviews;

  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    final displayName = json['displayName'] as Map<String, dynamic>?;
    final editorialSummary =
        json['editorialSummary'] as Map<String, dynamic>?;
    final location = json['location'] as Map<String, dynamic>?;
    final photos = (json['photos'] as List?) ?? const [];
    final types = (json['types'] as List?) ?? const [];
    final reviews = (json['reviews'] as List?) ?? const [];
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
      reviews: [
        for (final r in reviews)
          if (r is Map<String, dynamic>) GoogleReview.fromJson(r),
      ],
    );
  }
}

/// A single live Google review. Surfaced as a clearly-labeled SECONDARY section
/// on the detail page (Tabemina's own reviews stay primary).
///
/// COMPLIANCE: never cached/stored — built fresh from each live Place Details
/// response and kept only in memory for the open screen. Carries the Google
/// attribution data the policy requires: author display name, a link to the
/// author's Google profile ([authorUri]), and their avatar ([authorPhotoUri]).
/// [text] is coerced to plain text via [sanitizeReviewText].
class GoogleReview {
  const GoogleReview({
    required this.authorName,
    this.authorUri,
    this.authorPhotoUri,
    required this.rating,
    this.relativeTime,
    required this.text,
    this.textLanguageCode,
    this.originalText,
    this.originalTextLanguageCode,
  });

  final String authorName;

  /// Link to the author's Google Maps contributor profile (tappable).
  final String? authorUri;

  /// Author avatar URL (googleusercontent); safe for `Image.network`.
  final String? authorPhotoUri;
  final double rating;

  /// Localized "3 months ago"-style description straight from the API (we pass
  /// the app language as `languageCode`, so it comes back in-language).
  final String? relativeTime;

  /// Plain-text review body as shown — this is the localized/translated text
  /// when Google auto-translated it (HTML stripped — see [sanitizeReviewText]).
  final String text;

  /// Language of [text] (e.g. `en`). When it differs from
  /// [originalTextLanguageCode], [text] is a Google auto-translation.
  final String? textLanguageCode;

  /// The author's original words, plain-text. Null when Google returned no
  /// separate original (i.e. [text] is already the original).
  final String? originalText;

  /// Language of [originalText].
  final String? originalTextLanguageCode;

  /// True when [text] is a Google auto-translation of [originalText] — i.e. an
  /// original exists in a different language. Drives the "Translated by Google"
  /// caption + "See original" toggle.
  bool get isTranslated =>
      originalText != null &&
      originalTextLanguageCode != null &&
      originalTextLanguageCode != textLanguageCode;

  factory GoogleReview.fromJson(Map<String, dynamic> json) {
    final author = json['authorAttribution'] as Map<String, dynamic>?;
    final textBlock = json['text'] as Map<String, dynamic>?;
    final originalBlock = json['originalText'] as Map<String, dynamic>?;
    final rawText = (textBlock?['text'] as String?) ?? '';
    final rawOriginal = originalBlock?['text'] as String?;
    return GoogleReview(
      authorName: (author?['displayName'] as String?) ?? '',
      authorUri: author?['uri'] as String?,
      authorPhotoUri: author?['photoUri'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      relativeTime: json['relativePublishTimeDescription'] as String?,
      text: sanitizeReviewText(rawText),
      textLanguageCode: textBlock?['languageCode'] as String?,
      originalText:
          rawOriginal == null ? null : sanitizeReviewText(rawOriginal),
      originalTextLanguageCode: originalBlock?['languageCode'] as String?,
    );
  }
}

/// Defensive plain-text coercion for Google review bodies.
///
/// The Places API (New) returns plain text, but we strip any stray HTML tags
/// and unescape the common entities so the string drops straight into a [Text]
/// widget (which never interprets markup) — no HTML is ever rendered, closing
/// off any injection vector.
String sanitizeReviewText(String raw) {
  if (raw.isEmpty) return '';
  // Remove any tag-like sequences first, then unescape common entities. Any
  // entity that decodes back to `<`/`>` is still shown literally by [Text].
  final stripped = raw.replaceAll(RegExp(r'<[^>]*>'), '');
  return stripped
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#34;', '"')
      .replaceAll('&#39;', "'")
      .trim();
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
