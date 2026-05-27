import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../features/bookmarks/presentation/screens/bookmarks_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/mypage/presentation/screens/mypage_screen.dart';
import '../../features/restaurant_detail/presentation/screens/restaurant_detail_screen.dart';
import '../../features/review/presentation/screens/review_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/write_review/presentation/screens/write_review_screen.dart';
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
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const SplashScreen(),
        // Fade out the splash into home over 500ms.
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    ),
    // Write-review modal. CupertinoPage with fullscreenDialog: true gives us
    // the native iOS slide-up-from-bottom + swipe-down-to-dismiss behavior.
    // CustomTransitionPage *kills* the iOS back gesture, which is why we
    // can't reach for a manual SlideTransition here.
    GoRoute(
      path: AppRoutes.writeReview,
      pageBuilder: (context, state) => CupertinoPage<void>(
        key: state.pageKey,
        fullscreenDialog: true,
        child: WriteReviewScreen.fromExtra(state.extra),
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
