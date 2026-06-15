import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabemina/core/analytics/analytics_origin.dart';
import 'package:tabemina/core/providers/analytics_providers.dart';
import 'package:tabemina/core/services/analytics_service.dart';
import 'package:tabemina/features/restaurant_detail/presentation/providers/restaurant_viewed_provider.dart';

/// STEP 3-3 origin plumbing. Verifies the route-extra → origin resolution and
/// that the one-shot tracker logs `restaurant_viewed` with the resolved origin,
/// covering a representative subset of the push surfaces plus the absent-extra
/// (deep_link) default.
void main() {
  group('AnalyticsOrigin.fromExtra', () {
    test('passes an AnalyticsOrigin through unchanged', () {
      expect(
        AnalyticsOrigin.fromExtra(AnalyticsOrigin.searchResult),
        AnalyticsOrigin.searchResult,
      );
    });

    test('defaults to deepLink when extra is null', () {
      expect(AnalyticsOrigin.fromExtra(null), AnalyticsOrigin.deepLink);
    });

    test('defaults to deepLink for an unexpected extra type', () {
      expect(AnalyticsOrigin.fromExtra('home_feed'), AnalyticsOrigin.deepLink);
      expect(AnalyticsOrigin.fromExtra(42), AnalyticsOrigin.deepLink);
    });
  });

  group('restaurantViewedTrackerProvider', () {
    ({String name, Map<String, Object>? params}) logViewed(AnalyticsOrigin o) {
      final fake = _CapturingAnalytics();
      final container = ProviderContainer(
        overrides: [analyticsServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      // Reading the autoDispose family runs its body once → fires the event.
      container.read(
        restaurantViewedTrackerProvider((placeId: 'place_42', origin: o)),
      );
      return fake.events.single;
    }

    test('home_feed push logs origin home_feed', () {
      final e = logViewed(AnalyticsOrigin.homeFeed);
      expect(e.name, 'restaurant_viewed');
      expect(e.params, {'restaurant_id': 'place_42', 'origin': 'home_feed'});
    });

    test('search_result push logs origin search_result', () {
      expect(
        logViewed(AnalyticsOrigin.searchResult).params,
        {'restaurant_id': 'place_42', 'origin': 'search_result'},
      );
    });

    test('bookmark_list push logs origin bookmark_list', () {
      expect(
        logViewed(AnalyticsOrigin.bookmarkList).params,
        {'restaurant_id': 'place_42', 'origin': 'bookmark_list'},
      );
    });

    test('my_page grid push logs origin my_page', () {
      expect(
        logViewed(AnalyticsOrigin.myPage).params,
        {'restaurant_id': 'place_42', 'origin': 'my_page'},
      );
    });

    test('absent extra (deep_link default) logs origin deep_link', () {
      // Mirrors a push site that provides no extra (e.g. My Page grid / deep
      // link): the route resolves to deepLink via fromExtra(null).
      final origin = AnalyticsOrigin.fromExtra(null);
      expect(
        logViewed(origin).params,
        {'restaurant_id': 'place_42', 'origin': 'deep_link'},
      );
    });
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
