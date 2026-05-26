import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_keys.dart';
import '../models/nearby_restaurant.dart';

/// Thin client over Google Places (New) — only the endpoints the Home feed
/// needs are wired up.
///
/// Authentication uses the per-request `X-Goog-Api-Key` header. The companion
/// `X-Goog-FieldMask` trims the response to the fields we render; without it
/// the API rejects the request.
class PlacesApiDatasource {
  PlacesApiDatasource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://places.googleapis.com/v1';
  static const String _fieldMask =
      'places.id,places.displayName,places.rating,places.userRatingCount,'
      'places.priceLevel,places.photos,places.location';

  /// Restaurant Place primary types we accept for the "Popular near you"
  /// carousel.
  ///
  /// Sent as `includedPrimaryTypes` (not `includedTypes`) so a venue only
  /// matches when its *primary* business type is on the list. The looser
  /// `includedTypes` filter matched anything that *contained* a restaurant,
  /// which leaked hotels, malls, and Pokemon Centers into the carousel.
  ///
  /// Cafes, bakeries and dessert shops live in [_cafePrimaryTypes] and surface
  /// in the separate "Cafes nearby" section so the two feeds don't compete for
  /// the same slots.
  static const List<String> _restaurantPrimaryTypes = [
    'restaurant',
    'japanese_restaurant',
    'ramen_restaurant',
    'sushi_restaurant',
    'seafood_restaurant',
    'chinese_restaurant',
    'korean_restaurant',
    'italian_restaurant',
    'french_restaurant',
    'indian_restaurant',
    'mexican_restaurant',
    'thai_restaurant',
    'vietnamese_restaurant',
    'american_restaurant',
    'mediterranean_restaurant',
    'greek_restaurant',
    'turkish_restaurant',
    'barbecue_restaurant',
    'steak_house',
    'pizza_restaurant',
    'hamburger_restaurant',
    'vegan_restaurant',
    'vegetarian_restaurant',
    'brunch_restaurant',
    'bar',
    'meal_takeaway',
  ];

  static const List<String> _cafePrimaryTypes = [
    'cafe',
    'coffee_shop',
    'bakery',
    'ice_cream_shop',
    'dessert_shop',
  ];

  /// Nearby restaurants within [radiusMeters] of (lat, lng), capped by
  /// [maxResults]. Sorted server-side by popularity; callers can re-sort.
  ///
  /// [languageCode] is a 2-letter ISO code (en / ja / ko). The Places API
  /// returns `displayName` (and other localized fields) in that language.
  Future<List<NearbyRestaurant>> searchNearbyRestaurants({
    required double latitude,
    required double longitude,
    required String languageCode,
    double radiusMeters = 1500,
    int maxResults = 20,
  }) {
    return _searchNearby(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      maxResults: maxResults,
      languageCode: languageCode,
      includedPrimaryTypes: _restaurantPrimaryTypes,
    );
  }

  /// Nearby cafes / bakeries within [radiusMeters] of (lat, lng).
  ///
  /// Same shape as [searchNearbyRestaurants] but constrained to coffee /
  /// dessert primary types so the "Cafes nearby" carousel doesn't share slots
  /// with the restaurant feed.
  Future<List<NearbyRestaurant>> searchNearbyCafes({
    required double latitude,
    required double longitude,
    required String languageCode,
    double radiusMeters = 1500,
    int maxResults = 10,
  }) {
    return _searchNearby(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      maxResults: maxResults,
      languageCode: languageCode,
      includedPrimaryTypes: _cafePrimaryTypes,
    );
  }

  Future<List<NearbyRestaurant>> _searchNearby({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    required int maxResults,
    required String languageCode,
    required List<String> includedPrimaryTypes,
  }) async {
    final uri = Uri.parse('$_baseUrl/places:searchNearby');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': googleMapsApiKey,
        'X-Goog-FieldMask': _fieldMask,
      },
      body: jsonEncode({
        'includedPrimaryTypes': includedPrimaryTypes,
        'maxResultCount': maxResults,
        'rankPreference': 'POPULARITY',
        'languageCode': languageCode,
        'locationRestriction': {
          'circle': {
            'center': {'latitude': latitude, 'longitude': longitude},
            'radius': radiusMeters,
          },
        },
      }),
    );

    if (response.statusCode != 200) {
      throw PlacesApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final places = (decoded['places'] as List?) ?? const [];
    return places
        .map((p) => NearbyRestaurant.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// Build the image URL for a Places photo resource name.
  ///
  /// The endpoint returns a 302 to a googleusercontent.com URL; `Image.network`
  /// follows redirects automatically, so the URL is safe to use directly.
  static String photoUrl(String photoName, {int maxHeightPx = 400}) {
    return '$_baseUrl/$photoName/media'
        '?key=$googleMapsApiKey&maxHeightPx=$maxHeightPx';
  }
}

class PlacesApiException implements Exception {
  PlacesApiException({required this.statusCode, required this.body});
  final int statusCode;
  final String body;

  @override
  String toString() => 'PlacesApiException($statusCode): $body';
}
