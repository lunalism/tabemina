import 'package:go_router/go_router.dart';

import '../../features/bookmarks/presentation/screens/bookmarks_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/mypage/presentation/screens/mypage_screen.dart';
import '../../features/review/presentation/screens/review_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../shared/widgets/tab_scaffold.dart';

/// Route paths for the app's top-level destinations.
abstract class AppRoutes {
  static const String home = '/';
  static const String search = '/search';
  static const String review = '/review';
  static const String bookmarks = '/bookmarks';
  static const String mypage = '/mypage';
}

/// GoRouter configuration.
///
/// A [StatefulShellRoute.indexedStack] wraps the five tabs in [TabScaffold],
/// giving each tab its own navigator branch and preserving state across
/// switches.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
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
