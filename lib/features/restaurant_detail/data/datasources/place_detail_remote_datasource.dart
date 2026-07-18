import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_keys.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/not_found_exception.dart';
import '../models/place_detail.dart';

/// Thin client over Google Places (New) — Place Details endpoint.
///
/// Auth uses the per-request `X-Goog-Api-Key` header; `X-Goog-FieldMask`
/// limits the response to the fields the detail screen actually renders so
/// we don't pay for data we throw away.
class PlaceDetailRemoteDatasource {
  PlaceDetailRemoteDatasource({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://places.googleapis.com/v1';
  // NOTE: requesting `reviews.*` on this same Place Details call (rather than a
  // second request — that would double-bill) moves this call into the higher
  // Enterprise + Atmosphere SKU. That is expected/accepted. We pull only the
  // review subfields we render, not the whole `reviews` object.
  static const String _fieldMask =
      'id,displayName,formattedAddress,nationalPhoneNumber,'
      'internationalPhoneNumber,websiteUri,rating,userRatingCount,priceLevel,'
      'currentOpeningHours,regularOpeningHours,photos,types,primaryType,'
      'editorialSummary,googleMapsUri,location,businessStatus,'
      'reviews.rating,reviews.text,reviews.originalText,'
      'reviews.relativePublishTimeDescription,reviews.authorAttribution';

  Future<PlaceDetail> fetch(
    String placeId, {
    required String languageCode,
  }) async {
    final uri = Uri.parse('$_baseUrl/places/$placeId').replace(
      queryParameters: {'languageCode': languageCode},
    );
    final response = await _client.get(
      uri,
      headers: {
        'X-Goog-Api-Key': googleMapsApiKey,
        'X-Ios-Bundle-Identifier': kIosBundleIdentifier,
        'X-Goog-FieldMask': _fieldMask,
      },
    );

    if (response.statusCode == 404) {
      // Places returns NOT_FOUND for ids that no longer resolve (closed
      // place, merged duplicate, removed listing) — a permanent condition,
      // not a transient failure. Distinct type so the UI can show a
      // "no longer available" state instead of a retry that can never
      // succeed.
      throw PlaceNotFoundException(body: response.body);
    }
    if (response.statusCode != 200) {
      throw PlaceDetailException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return PlaceDetail.fromJson(decoded);
  }

  /// Build the image URL for a Places photo resource name.
  ///
  /// The endpoint 302-redirects to googleusercontent.com; `Image.network`
  /// follows redirects so the URL is safe to feed in directly.
  static String photoUrl(
    String photoName, {
    int maxHeightPx = 800,
    int maxWidthPx = 800,
  }) {
    return '$_baseUrl/$photoName/media'
        '?maxHeightPx=$maxHeightPx'
        '&maxWidthPx=$maxWidthPx'
        '&key=$googleMapsApiKey';
  }
}

class PlaceDetailException implements Exception {
  PlaceDetailException({required this.statusCode, required this.body});
  final int statusCode;
  final String body;

  @override
  String toString() => 'PlaceDetailException($statusCode): $body';
}

/// The place id no longer resolves (Places NOT_FOUND). Implements the core
/// [NotFoundException] marker so `classifyError` maps it to the non-retriable
/// not-found presentation.
class PlaceNotFoundException extends PlaceDetailException
    implements NotFoundException {
  PlaceNotFoundException({required super.body}) : super(statusCode: 404);
}
