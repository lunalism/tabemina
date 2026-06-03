import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/review_entity.dart';
import '../../features/blocking/presentation/screens/blocked_users_screen.dart';
import '../../features/bookmarks/presentation/screens/bookmarks_screen.dart';
import '../../features/eula/presentation/providers/eula_providers.dart';
import '../../features/eula/presentation/screens/eula_gate_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/mypage/presentation/screens/mypage_screen.dart';
import '../../features/restaurant_detail/presentation/screens/restaurant_detail_screen.dart';
import '../../features/review/presentation/screens/review_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/write_review/presentation/screens/write_review_screen.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../shared/widgets/tab_scaffold.dart';

/// Route paths for the app's top-level destinations.
abstract class AppRoutes {
  static const String splash = '/splash';
  static const String home = '/';
  static const String search = '/search';
  static const String review = '/review';
  static const String bookmarks = '/bookmarks';
  static const String mypage = '/mypage';
  static const String restaurantDetail = '/restaurant';
  static const String writeReview = '/write-review';
  static const String editReview = '/edit-review';
  static const String settings = '/settings';
  static const String blockedUsers = '/settings/blocked-users';
  static const String eula = '/eula';

  static String restaurantDetailFor(String placeId) =>
      '$restaurantDetail/$placeId';
}

/// GoRouter configuration.
///
/// The app opens on [AppRoutes.splash], which lives outside the shell so it has
/// no tab bar. The splash uses `context.go(home)` (not push), replacing the
/// stack so the user can't navigate back to it. A
/// [StatefulShellRoute.indexedStack] then wraps the five tabs in [TabScaffold],
/// giving each tab its own navigator branch and preserving state across
/// switches.
///
/// Exposed as a provider (rather than a bare global) so the [GoRouter.redirect]
/// guard can read Riverpod consent state and a [GoRouter.refreshListenable] can
/// re-run that guard whenever auth or EULA-consent changes. The provider builds
/// exactly once — it only `ref.listen`s (never `watch`es), so the router
/// instance is stable and navigation state is never thrown away.
final routerProvider = Provider<GoRouter>((ref) {
  // Bumping this notifier asks GoRouter to re-evaluate `redirect`. We pulse it
  // on every auth change and every consent-state change.
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.listen(eulaConsentProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      // Never interfere with the splash — it owns the initial hand-off to home.
      if (loc == AppRoutes.splash) return null;

      final consent = ref.read(eulaConsentProvider);
      return consent.maybeWhen(
        data: (status) {
          final mustConsent = status == EulaConsentStatus.gateRequired;
          if (mustConsent && loc != AppRoutes.eula) return AppRoutes.eula;
          // Authed-and-accepted or guest: keep them out of the gate.
          if (!mustConsent && loc == AppRoutes.eula) return AppRoutes.home;
          return null;
        },
        // While consent is still resolving (or errored), don't force a
        // redirect — the refreshListenable re-runs this once it settles.
        orElse: () => null,
      );
    },
    routes: [
      // EULA consent gate. A MaterialPage (no iOS edge-swipe) reached via
      // redirect; the screen itself blocks back with PopScope. Lives outside
      // the shell so it covers the whole screen with no tab bar.
      GoRoute(
        path: AppRoutes.eula,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: EulaGateScreen()),
      ),
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SplashScreen(),
          // Fade out the splash into home over 500ms.
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
        ),
      ),
      // Write-review push. Uses the standard iOS push (slide-from-right) so
      // the user can dismiss with the left-edge swipe-back gesture. We avoid
      // fullscreenDialog: true on purpose — its swipe-down dismiss collides
      // with iOS Control Center / Notification Center on real devices.
      GoRoute(
        path: AppRoutes.writeReview,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: WriteReviewScreen.fromExtra(state.extra),
        ),
      ),
      // Edit-review push — same screen in edit mode, prefilled from the
      // ReviewEntity passed via `extra`. Standard push so the left-edge
      // swipe-back gesture works.
      GoRoute(
        path: AppRoutes.editReview,
        pageBuilder: (context, state) {
          final review = state.extra as ReviewEntity?;
          return CupertinoPage<void>(
            key: state.pageKey,
            child: review != null
                ? WriteReviewScreen.edit(review)
                : const WriteReviewScreen(),
          );
        },
      ),
      // Settings (My Page gear icon). Standard iOS push.
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
      // Blocked-users management (Settings → Blocked users). A sibling route of
      // /settings, pushed on top, so it resolves exactly as before.
      GoRoute(
        path: AppRoutes.blockedUsers,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          child: const BlockedUsersScreen(),
        ),
      ),
      // Restaurant detail. CupertinoPage gives the native iOS slide-from-right
      // push and — critically — the interactive swipe-back gesture from the
      // left edge. Material's default page route swallows that on iOS.
      GoRoute(
        path: '${AppRoutes.restaurantDetail}/:placeId',
        pageBuilder: (context, state) {
          final placeId = state.pathParameters['placeId']!;
          return CupertinoPage<void>(
            key: state.pageKey,
            child: RestaurantDetailScreen(placeId: placeId),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            TabScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.search,
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.review,
                builder: (context, state) => const ReviewScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.bookmarks,
                builder: (context, state) => const BookmarksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.mypage,
                builder: (context, state) => const MyPageScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
