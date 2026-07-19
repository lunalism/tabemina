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
  /// Cap the details request rather than riding the http default (~60s):
  /// this is a first-impression screen, so a dead network should resolve to
  /// the error view in seconds. Same 10s bound as GPS acquisition in
  /// [LocationService]. The resulting [TimeoutException] classifies as a
  /// network error (see `classifyError`), not a server one.
  static const Duration _requestTimeout = Duration(seconds: 10);
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
    ).timeout(_requestTimeout);

    if (response.statusCode == 404 || _isInvalidPlaceId(response)) {
      // Places returns NOT_FOUND for ids that no longer resolve (closed
      // place, merged duplicate, removed listing) and 400 INVALID_ARGUMENT
      // for ids that never resolved (malformed / mangled). Both are
      // permanent conditions, not transient failures. Distinct type so the
      // UI can show a "no longer available" state instead of a retry that
      // can never succeed.
      throw PlaceNotFoundException(
        statusCode: response.statusCode,
        body: response.body,
      );
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

  /// Whether a 400 from the details endpoint means "this place id can never
  /// resolve". Matched on the error payload's `error.status`, not the bare
  /// status code, so a 400 without the Places error shape (a proxy, a
  /// non-JSON error page) still surfaces as a server error instead of
  /// masquerading as not-found.
  static bool _isInvalidPlaceId(http.Response response) {
    if (response.statusCode != 400) return false;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return false;
      final error = decoded['error'];
      return error is Map<String, dynamic> &&
          error['status'] == 'INVALID_ARGUMENT';
    } on FormatException {
      return false;
    }
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

/// The place id will never resolve — Places NOT_FOUND (404) or
/// INVALID_ARGUMENT (400, malformed id). Implements the core
/// [NotFoundException] marker so `classifyError` maps it to the
/// non-retriable not-found presentation.
class PlaceNotFoundException extends PlaceDetailException
    implements NotFoundException {
  PlaceNotFoundException({required super.body, super.statusCode = 404});
}
