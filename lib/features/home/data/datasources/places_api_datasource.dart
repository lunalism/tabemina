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

  /// Food-and-drink Place primary types we accept in nearby search.
  ///
  /// Sent as `includedPrimaryTypes` (not `includedTypes`) so a venue only
  /// matches when its *primary* business type is on the list. The looser
  /// `includedTypes` filter matched anything that *contained* a restaurant,
  /// which leaked hotels, malls, and Pokemon Centers into the carousel.
  static const List<String> _foodPrimaryTypes = [
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
    'cafe',
    'coffee_shop',
    'bakery',
    'bar',
    'ice_cream_shop',
    'dessert_shop',
    'meal_takeaway',
  ];

  /// Nearby restaurants within [radiusMeters] of (lat, lng), capped by
  /// [maxResults]. Sorted server-side by popularity; callers can re-sort.
  Future<List<NearbyRestaurant>> searchNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radiusMeters = 1500,
    int maxResults = 10,
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
        'includedPrimaryTypes': _foodPrimaryTypes,
        'maxResultCount': maxResults,
        'rankPreference': 'POPULARITY',
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
