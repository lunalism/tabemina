import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/app_locale_provider.dart';
import '../../core/router/app_router.dart';
import '../../presentation/widgets/auth_gate.dart';

/// App shell: hosts the five [StatefulShellRoute.indexedStack] branches and
/// renders the bottom navigation as a **floating frosted tray with a center
/// docked FAB**.
///
/// The tray exposes FOUR real tabs — Home, Search | [FAB] | Bookmarks, My Page
/// — mapped to branch indices `[0, 1, 3, 4]`. Branch 2 (the legacy "Review"
/// branch) is intentionally never shown: writing a review is the center FAB,
/// which pushes `/write-review` over the current tab (auth-gated), exactly as
/// the old Review tab did. The branch + route are left untouched.
class TabScaffold extends ConsumerWidget {
  const TabScaffold({super.key, required this.navigationShell});

  /// The navigation shell driving the indexed stack of tab branches.
  final StatefulNavigationShell navigationShell;

  static const double _trayHeight = 64;
  static const double _fabSize = 54;
  static const double _edgeInset = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = NavLabels.of(ref.watch(appLocaleProvider).languageCode);
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    void goBranch(int branch) {
      navigationShell.goBranch(
        branch,
        initialLocation: branch == navigationShell.currentIndex,
      );
    }

    // Writing a review requires auth — gate behind the login sheet first, then
    // push the write-review flow over the current tab (no `extra`, so the
    // screen opens on its restaurant-select step).
    void onWriteReview() {
      requireAuth(
        context,
        ref,
        action: () => context.push(AppRoutes.writeReview),
      );
    }

    final tabs = <Widget>[
      _NavTab(
        activeIcon: Icons.home,
        inactiveIcon: Icons.home_outlined,
        label: labels.home,
        active: navigationShell.currentIndex == 0,
        onTap: () => goBranch(0),
      ),
      _NavTab(
        activeIcon: Icons.search,
        inactiveIcon: Icons.search,
        label: labels.search,
        active: navigationShell.currentIndex == 1,
        onTap: () => goBranch(1),
      ),
      _NavTab(
        activeIcon: Icons.bookmark,
        inactiveIcon: Icons.bookmark_outline,
        label: labels.bookmarks,
        active: navigationShell.currentIndex == 3,
        onTap: () => goBranch(3),
      ),
      _NavTab(
        activeIcon: Icons.person,
        inactiveIcon: Icons.person_outline,
        label: labels.myPage,
        active: navigationShell.currentIndex == 4,
        onTap: () => goBranch(4),
      ),
    ];

    return Scaffold(
      // Floating tray overlays the content; let the body run full-bleed under it.
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              // Room for the FAB to poke above the tray's top edge.
              height: safeBottom + _edgeInset + _trayHeight + _fabSize / 2,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: _edgeInset,
                    right: _edgeInset,
                    bottom: safeBottom + _edgeInset,
                    height: _trayHeight,
                    child: _FloatingTray(tabs: tabs),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    // Overlap the tray's top edge by ~half the FAB.
                    bottom: safeBottom + _edgeInset + _trayHeight - _fabSize / 2,
                    child: Center(
                      child: _CenterFab(
                        tooltip: labels.writeReview,
                        onTap: onWriteReview,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The frosted, inset, rounded tray holding the four tabs split 2 + 2 around a
/// center gap reserved for the FAB.
class _FloatingTray extends StatelessWidget {
  const _FloatingTray({required this.tabs});

  final List<Widget> tabs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Specified literal tray ARGB values (frosted glass surface).
    final fill = isDark ? const Color(0xBC252420) : const Color(0xB8FFFFFF);
    final border = isDark ? const Color(0x12FFFFFF) : const Color(0x0D000000);
    final shadow = isDark ? const Color(0x59000000) : const Color(0x1A000000);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 18, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(child: tabs[0]),
                Expanded(child: tabs[1]),
                const SizedBox(width: 56), // center gap under the FAB
                Expanded(child: tabs[2]),
                Expanded(child: tabs[3]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One tab: filled/outline icon swap + label, coral when active, warm-gray when
/// inactive. Label font is 10 so the longest JP labels never truncate.
class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = active ? c.tabActive : c.tabInactive;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: active ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: Icon(active ? activeIcon : inactiveIcon, size: 24, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 10,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Center docked "Write a review" FAB. Coral fill is the LIGHT brand value in
/// both modes (keeps strong white-icon contrast); it sits raised over the tray.
class _CenterFab extends StatelessWidget {
  const _CenterFab({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shadowColor = isDark
        ? const Color(0x73000000)
        : AppColors.brandCoralLight.withValues(alpha: 0.36);

    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: TabScaffold._fabSize,
            height: TabScaffold._fabSize,
            decoration: BoxDecoration(
              color: AppColors.brandCoralLight,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: AppColors.onPrimary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// Localized bottom-nav copy (KO / JA / EN) via the project's manual
/// `XxxLabels.of(lang)` convention.
class NavLabels {
  const NavLabels({
    required this.home,
    required this.search,
    required this.bookmarks,
    required this.myPage,
    required this.writeReview,
  });

  final String home;
  final String search;
  final String bookmarks;
  final String myPage;
  final String writeReview;

  static NavLabels of(String code) {
    switch (code) {
      case 'ja':
        return const NavLabels(
          home: 'ホーム',
          search: '検索',
          bookmarks: 'ブックマーク',
          myPage: 'マイページ',
          writeReview: 'レビューを書く',
        );
      case 'ko':
        return const NavLabels(
          home: '홈',
          search: '검색',
          bookmarks: '북마크',
          myPage: '마이페이지',
          writeReview: '리뷰 작성',
        );
      case 'en':
      default:
        return const NavLabels(
          home: 'Home',
          search: 'Search',
          bookmarks: 'Bookmarks',
          myPage: 'My Page',
          writeReview: 'Write a review',
        );
    }
  }
}
