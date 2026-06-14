import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tabemina/core/analytics/analytics_router_listener.dart';
import 'package:tabemina/core/services/analytics_service.dart';

/// Regression guard for [AnalyticsRouterListener] — the app's automatic
/// `screen_view` mechanism.
///
/// Drives a real GoRouter that mirrors the app's shape (a
/// StatefulShellRoute.indexedStack with 5 branches + root routes reached via
/// push) and asserts the exact screen_name SEQUENCE the listener logs across
/// every navigation kind. A future go_router upgrade that changes leaf
/// resolution (RouteMatchList.last / ImperativeRouteMatch.route) MUST fail here.
///
/// Cases (a)-(e) are the original screen flows; (f)/(g) are the two the old
/// observer got wrong (logged nothing / logged stale); (h) is the open side of
/// the write_review funnel (TabScaffold index 2 -> push write_review).
void main() {
  late _RecordingAnalytics analytics;

  setUp(() => analytics = _RecordingAnalytics());

  /// Builds the router, pumps the first frame, then attaches the listener AFTER
  /// the initial route is parsed (so the cold-start screen is captured by the
  /// constructor's one-shot read — mirroring a post-first-frame wiring).
  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required String initialLocation,
  }) async {
    final router = _buildRouter(initialLocation: initialLocation);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    AnalyticsRouterListener(router, analytics);
    return router;
  }

  testWidgets('(a) cold start -> home => [home]', (tester) async {
    await pumpApp(tester, initialLocation: '/');
    expect(analytics.screens, ['home']);
  });

  testWidgets('(b)+(c) home -> restaurant_detail (id in path) -> back', (
    tester,
  ) async {
    final router = await pumpApp(tester, initialLocation: '/');
    router.push('/restaurant/abc123XYZ');
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();

    expect(analytics.screens, ['home', 'restaurant_detail', 'home']);
    // No id ever leaks into a screen_name.
    expect(analytics.screens.any((s) => s.contains('abc123XYZ')), isFalse);
    expect(analytics.screens.any((s) => s.contains(':')), isFalse);
  });

  testWidgets('(d) tab switches home->search->bookmarks->home', (tester) async {
    final router = await pumpApp(tester, initialLocation: '/');
    router.go('/search');
    await tester.pumpAndSettle();
    router.go('/bookmarks');
    await tester.pumpAndSettle();
    router.go('/');
    await tester.pumpAndSettle();

    expect(analytics.screens, ['home', 'search', 'bookmarks', 'home']);
  });

  testWidgets('(e) my_page->settings->blocked_users +back +back', (
    tester,
  ) async {
    final router = await pumpApp(tester, initialLocation: '/mypage');
    router.push('/settings');
    await tester.pumpAndSettle();
    router.push('/settings/blocked-users');
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();

    expect(analytics.screens, [
      'my_page',
      'settings',
      'blocked_users',
      'settings',
      'my_page',
    ]);
  });

  testWidgets('(f) bookmarks -> context.go(home) logs home', (tester) async {
    // The old observer logged NOTHING here (no push/pop, not a tab tap).
    final router = await pumpApp(tester, initialLocation: '/bookmarks');
    router.go('/');
    await tester.pumpAndSettle();

    expect(analytics.screens, ['bookmarks', 'home']);
    expect(analytics.screens.last, 'home');
  });

  testWidgets('(g) delete_account -> context.go(home) logs home, not stale', (
    tester,
  ) async {
    // The old observer logged STALE my_page here via reassertTab().
    final router = await pumpApp(tester, initialLocation: '/mypage');
    router.push('/settings');
    await tester.pumpAndSettle();
    router.push('/settings/delete-account');
    await tester.pumpAndSettle();
    router.go('/');
    await tester.pumpAndSettle();

    expect(analytics.screens, ['my_page', 'settings', 'delete_account', 'home']);
    expect(analytics.screens.last, 'home'); // NOT 'my_page'
  });

  testWidgets('(h) open write_review (TabScaffold idx 2 push) logs once', (
    tester,
  ) async {
    // Mirrors TabScaffold's center tab: context.push(AppRoutes.writeReview).
    // The 7 original cases never exercised write_review — this locks the
    // form-open side of the open->submit funnel.
    final router = await pumpApp(tester, initialLocation: '/');
    router.push('/write-review');
    await tester.pumpAndSettle();

    expect(analytics.screens, ['home', 'write_review']);
    // Exactly once, no id.
    expect(analytics.screens.where((s) => s == 'write_review').length, 1);
    expect(analytics.screens.any((s) => s.contains(':')), isFalse);
  });
}

/// Router mirroring the real app: 5-branch indexedStack shell + root routes
/// reached via push. Route names match the production names.
GoRouter _buildRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        name: 'restaurant_detail',
        path: '/restaurant/:placeId',
        builder: (c, s) => const _Stub('detail'),
      ),
      GoRoute(
        name: 'write_review',
        path: '/write-review',
        builder: (c, s) => const _Stub('write_review'),
      ),
      GoRoute(
        name: 'settings',
        path: '/settings',
        builder: (c, s) => const _Stub('settings'),
      ),
      GoRoute(
        name: 'blocked_users',
        path: '/settings/blocked-users',
        builder: (c, s) => const _Stub('blocked_users'),
      ),
      GoRoute(
        name: 'delete_account',
        path: '/settings/delete-account',
        builder: (c, s) => const _Stub('delete_account'),
      ),
      StatefulShellRoute.indexedStack(
        builder: (c, s, navigationShell) => navigationShell,
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(name: 'home', path: '/', builder: (c, s) => const _Stub('home')),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'search',
                path: '/search',
                builder: (c, s) => const _Stub('search'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'review',
                path: '/review',
                builder: (c, s) => const _Stub('review'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'bookmarks',
                path: '/bookmarks',
                builder: (c, s) => const _Stub('bookmarks'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: 'my_page',
                path: '/mypage',
                builder: (c, s) => const _Stub('my_page'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _Stub extends StatelessWidget {
  const _Stub(this.label);
  final String label;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(label)));
}

class _RecordingAnalytics implements AnalyticsService {
  final List<String> screens = [];

  @override
  Future<void> logScreenView(String screenName) async => screens.add(screenName);

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {}

  @override
  Future<void> setUserId(String? id) async {}
}
