import '../services/analytics_service.dart';
import 'analytics_origin.dart';

/// Typed facade over [AnalyticsService.logEvent] — the single auditable place
/// where the app's action-event schema lives. One method per event, with fixed
/// snake_case names and typed parameters, so call sites can't drift the schema.
///
/// ## PII rule
/// NEVER log free text. In particular the **raw search query is never passed
/// here** — search exposes only `has_text_query` (a bool). Restaurant / review /
/// bookmark ids are opaque Firestore / Places doc ids (not PII) and are fine to
/// log.
///
/// ## Wire format
/// The vendored `firebase_analytics` rejects parameter values that aren't
/// `String` / `num` / `null` (see its `_assertParameterTypesAreCorrect`). Each
/// method therefore takes a typed `bool` but encodes it as `1` / `0` on the
/// wire. Optional params (`atmosphere`, `origin`) are omitted entirely when
/// null rather than sent as empty strings.
class AnalyticsEvents {
  const AnalyticsEvents(this._analytics);

  final AnalyticsService _analytics;

  static int _flag(bool value) => value ? 1 : 0;

  /// Sign-in completed. [method] is `'google'` | `'apple'`.
  Future<void> login({required String method, required bool isNewUser}) {
    return _analytics.logEvent('login', parameters: {
      'method': method,
      'is_new_user': _flag(isNewUser),
    });
  }

  /// A search actually executed (post-debounce / filter apply) and returned
  /// [resultCount] results. [filters] is a low-cardinality summary (the active
  /// cuisine filter name). [hasTextQuery] is whether the user typed anything —
  /// the raw query text is intentionally NOT a parameter.
  Future<void> search({
    required bool hasTextQuery,
    required String filters,
    String? atmosphere,
    required int resultCount,
  }) {
    return _analytics.logEvent('search', parameters: {
      'has_text_query': _flag(hasTextQuery),
      'filters': filters,
      'atmosphere': ?atmosphere,
      'result_count': resultCount,
    });
  }

  /// A restaurant detail page was opened. [origin] is the surface it was opened
  /// from; omitted from the payload when null.
  Future<void> restaurantViewed({
    required String restaurantId,
    AnalyticsOrigin? origin,
  }) {
    return _analytics.logEvent('restaurant_viewed', parameters: {
      'restaurant_id': restaurantId,
      'origin': ?origin?.wireValue,
    });
  }

  /// A review write to Firestore confirmed. [isEdit] disambiguates an edit from
  /// a new post (both share the `write_review` screen_name). [atmosphere] is a
  /// summary of the selected mood tags, or null when none were chosen.
  Future<void> reviewSubmitted({
    required num rating,
    String? atmosphere,
    required String restaurantId,
    required bool isEdit,
    required int photoCount,
  }) {
    return _analytics.logEvent('review_submitted', parameters: {
      'rating': rating,
      'atmosphere': ?atmosphere,
      'restaurant_id': restaurantId,
      'is_edit': _flag(isEdit),
      'photo_count': photoCount,
    });
  }

  /// A photo's first compress attempt returned null and a retry re-encode is
  /// about to run. Measures how often the native codec hiccups (dominant cause:
  /// iOS HEIC decode on ordinary photos) — invisible in production otherwise.
  /// No parameters: IDFA-free and carries no per-photo data.
  Future<void> photoCompressRetry() {
    return _analytics.logEvent('photo_compress_retry');
  }

  /// A photo failed to compress even after the retry — it can never be stripped,
  /// so the upload is blocked (the original with EXIF is never sent). Tracks the
  /// genuinely-unprocessable rate. No parameters (IDFA-free).
  Future<void> photoCompressUnprocessable() {
    return _analytics.logEvent('photo_compress_unprocessable');
  }

  /// A bookmark was added (toggle-on persisted). [origin] is the surface where
  /// the action happened; optional.
  Future<void> bookmarkAdded({
    required String restaurantId,
    AnalyticsOrigin? origin,
  }) {
    return _analytics.logEvent('bookmark_added', parameters: {
      'restaurant_id': restaurantId,
      'origin': ?origin?.wireValue,
    });
  }

  /// A bookmark was removed (toggle-off persisted). [origin] is the surface
  /// where the action happened; optional.
  Future<void> bookmarkRemoved({
    required String restaurantId,
    AnalyticsOrigin? origin,
  }) {
    return _analytics.logEvent('bookmark_removed', parameters: {
      'restaurant_id': restaurantId,
      'origin': ?origin?.wireValue,
    });
  }
}
