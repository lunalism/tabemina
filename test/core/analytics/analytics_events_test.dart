import 'package:flutter_test/flutter_test.dart';
import 'package:tabemina/core/analytics/analytics_events.dart';
import 'package:tabemina/core/services/analytics_service.dart';

/// Schema + PII guard for the [AnalyticsEvents] facade. Asserts each method
/// emits the exact event name and parameter map, that booleans are encoded as
/// 1/0 num (the vendored firebase_analytics rejects bool values), and — most
/// importantly — that the raw search query is never present in any form.
void main() {
  late _CapturingAnalytics analytics;
  late AnalyticsEvents events;

  setUp(() {
    analytics = _CapturingAnalytics();
    events = AnalyticsEvents(analytics);
  });

  ({String name, Map<String, Object>? params}) single() => analytics.events.single;

  group('login', () {
    test('emits name + method + is_new_user as 1/0', () {
      events.login(method: 'google', isNewUser: true);
      expect(single().name, 'login');
      expect(single().params, {'method': 'google', 'is_new_user': 1});
      expect(single().params!['is_new_user'], isA<num>());
    });

    test('is_new_user false encodes to 0', () {
      events.login(method: 'apple', isNewUser: false);
      expect(single().params!['is_new_user'], 0);
    });
  });

  group('search', () {
    test('emits has_text_query/filters/result_count; NO raw query', () {
      events.search(hasTextQuery: true, filters: 'ramen', resultCount: 7);
      expect(single().name, 'search');
      expect(single().params, {
        'has_text_query': 1,
        'filters': 'ramen',
        'result_count': 7,
      });
    });

    test('NEVER contains a query / search_term key or the text', () {
      events.search(hasTextQuery: true, filters: 'all', resultCount: 3);
      final params = single().params!;
      expect(params.containsKey('query'), isFalse);
      expect(params.containsKey('search_term'), isFalse);
      expect(params.containsKey('q'), isFalse);
      expect(params.containsKey('text'), isFalse);
      // Only the four sanctioned keys may appear (atmosphere omitted here).
      expect(
        params.keys.toSet(),
        {'has_text_query', 'filters', 'result_count'},
      );
    });

    test('has_text_query false encodes to 0', () {
      events.search(hasTextQuery: false, filters: 'all', resultCount: 0);
      expect(single().params!['has_text_query'], 0);
    });

    test('atmosphere included only when non-null', () {
      events.search(
        hasTextQuery: false,
        filters: 'all',
        atmosphere: 'quiet',
        resultCount: 1,
      );
      expect(single().params!['atmosphere'], 'quiet');
    });
  });

  group('restaurant_viewed', () {
    test('id only when origin omitted', () {
      events.restaurantViewed(restaurantId: 'place_123');
      expect(single().name, 'restaurant_viewed');
      expect(single().params, {'restaurant_id': 'place_123'});
    });

    test('includes origin when provided', () {
      events.restaurantViewed(restaurantId: 'place_123', origin: 'home_feed');
      expect(single().params, {
        'restaurant_id': 'place_123',
        'origin': 'home_feed',
      });
    });
  });

  group('review_submitted', () {
    test('full param map with is_edit as 1/0', () {
      events.reviewSubmitted(
        rating: 4,
        atmosphere: 'date,quiet',
        restaurantId: 'place_9',
        isEdit: false,
        photoCount: 2,
      );
      expect(single().name, 'review_submitted');
      expect(single().params, {
        'rating': 4,
        'atmosphere': 'date,quiet',
        'restaurant_id': 'place_9',
        'is_edit': 0,
        'photo_count': 2,
      });
    });

    test('is_edit true encodes to 1; atmosphere omitted when null', () {
      events.reviewSubmitted(
        rating: 5,
        restaurantId: 'place_9',
        isEdit: true,
        photoCount: 0,
      );
      final params = single().params!;
      expect(params['is_edit'], 1);
      expect(params.containsKey('atmosphere'), isFalse);
    });
  });

  group('bookmark', () {
    test('bookmark_added id only', () {
      events.bookmarkAdded(restaurantId: 'place_1');
      expect(single().name, 'bookmark_added');
      expect(single().params, {'restaurant_id': 'place_1'});
    });

    test('bookmark_removed with origin', () {
      events.bookmarkRemoved(restaurantId: 'place_1', origin: 'bookmark_list');
      expect(single().name, 'bookmark_removed');
      expect(single().params, {
        'restaurant_id': 'place_1',
        'origin': 'bookmark_list',
      });
    });
  });

  test('all encoded param values are String or num (Firebase-valid)', () {
    events.login(method: 'google', isNewUser: true);
    events.search(hasTextQuery: true, filters: 'all', resultCount: 1);
    events.reviewSubmitted(
      rating: 3,
      restaurantId: 'p',
      isEdit: true,
      photoCount: 1,
    );
    for (final e in analytics.events) {
      for (final v in e.params!.values) {
        expect(v is String || v is num, isTrue,
            reason: '$v in ${e.name} must be String or num, not ${v.runtimeType}');
      }
    }
  });
}

class _CapturingAnalytics implements AnalyticsService {
  final List<({String name, Map<String, Object>? params})> events = [];

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    events.add((name: name, params: parameters));
  }

  @override
  Future<void> logScreenView(String screenName) async {}

  @override
  Future<void> setUserId(String? id) async {}
}
