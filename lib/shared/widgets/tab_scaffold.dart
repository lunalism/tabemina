import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/app_locale_provider.dart';
import '../../core/providers/nav_compact_provider.dart';
import '../../core/router/app_router.dart';
import '../../presentation/widgets/auth_gate.dart';

/// Floating-nav geometry (single source of truth, shared with scrollable
/// screens via [floatingNavContentInset]).
const double kNavEdgeInset = 12;
const double kNavBarExpandedHeight = 64;
const double kNavBarCompactHeight = 48;

/// On-screen footprint of the floating nav above the bottom safe-area inset,
/// sized to the EXPANDED bar (its max) so content always clears it: expanded
/// bar height + bottom margin.
const double kFloatingNavInset = kNavBarExpandedHeight + kNavEdgeInset;

/// Bottom padding a scrollable tab screen should reserve so its last item
/// clears the floating nav bar (at its tallest).
///
/// Adds `MediaQuery.padding.bottom` (not `viewPadding`) so it auto-adapts: the
/// home-indicator inset for a full-bleed scrollable, or 0 inside a [SafeArea]
/// that already reserved it.
double floatingNavContentInset(BuildContext context) =>
    kFloatingNavInset + MediaQuery.paddingOf(context).bottom;

const Duration _navAnim = Duration(milliseconds: 200);

/// App shell: hosts the five [StatefulShellRoute.indexedStack] branches and
/// renders the bottom navigation as a single **floating frosted bar** with five
/// flat slots — Home, Search, [Review], Bookmarks, My Page.
///
/// The four tabs map to branch indices `[0, 1, 3, 4]`. The center **Review**
/// slot is an ACTION (not a tab): always coral, never selected; it pushes
/// `/write-review` over the current tab (auth-gated). Branch 2 (legacy Review
/// branch) + the route are untouched. The bar shrinks on scroll-down and grows
/// back on scroll-up (it never hides).
class TabScaffold extends ConsumerWidget {
  const TabScaffold({super.key, required this.navigationShell});

  /// The navigation shell driving the indexed stack of tab branches.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = NavLabels.of(ref.watch(appLocaleProvider).languageCode);
    final compact = ref.watch(navCompactProvider);
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    // Read from the shell's own context so the bar tracks the OS keyboard
    // animation. Uniform across all tabs: keyboard visible → bar hidden.
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    void goBranch(int branch) {
      navigationShell.goBranch(
        branch,
        initialLocation: branch == navigationShell.currentIndex,
      );
    }

    // Writing a review requires auth — gate behind the login sheet first, then
    // push the write-review flow over the current tab (no `extra`, so the
    // screen opens on its restaurant-select step). Same as the old FAB.
    void onWriteReview() {
      requireAuth(
        context,
        ref,
        action: () => context.push(AppRoutes.writeReview),
      );
    }

    return Scaffold(
      // Floating bar overlays the content; let the body run full-bleed under it.
      extendBody: true,
      // Don't resize the shell for the keyboard — branch screens own their
      // insets, and resizing here would jump the bar above the keyboard
      // before the slide-out animation can play.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: kNavEdgeInset,
            right: kNavEdgeInset,
            // Bottom-anchored + no fixed height, so the bar shrinks/grows from
            // its bottom edge as it animates between expanded/compact.
            bottom: safeBottom + kNavEdgeInset,
            // While the keyboard is up the bar slides off the bottom edge and
            // fades; IgnorePointer keeps the invisible bar from eating taps.
            child: IgnorePointer(
              ignoring: keyboardVisible,
              child: AnimatedSlide(
                // 2x own height clears bar + margins + home indicator.
                offset: keyboardVisible ? const Offset(0, 2) : Offset.zero,
                duration: _navAnim,
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: keyboardVisible ? 0 : 1,
                  duration: _navAnim,
                  curve: Curves.easeOut,
                  child: _FloatingBar(
                    compact: compact,
                    currentIndex: navigationShell.currentIndex,
                    labels: labels,
                    onTabSelected: goBranch,
                    onReview: onWriteReview,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The frosted, inset, rounded bar holding five evenly-spaced slots.
class _FloatingBar extends StatelessWidget {
  const _FloatingBar({
    required this.compact,
    required this.currentIndex,
    required this.labels,
    required this.onTabSelected,
    required this.onReview,
  });

  final bool compact;
  final int currentIndex;
  final NavLabels labels;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Specified literal frosted-glass ARGB values.
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
          child: AnimatedContainer(
            duration: _navAnim,
            curve: Curves.easeOut,
            height: compact ? kNavBarCompactHeight : kNavBarExpandedHeight,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _NavTab(
                    activeIcon: Icons.home,
                    inactiveIcon: Icons.home_outlined,
                    label: labels.home,
                    active: currentIndex == 0,
                    compact: compact,
                    onTap: () => onTabSelected(0),
                  ),
                ),
                Expanded(
                  child: _NavTab(
                    activeIcon: Icons.search,
                    inactiveIcon: Icons.search,
                    label: labels.search,
                    active: currentIndex == 1,
                    compact: compact,
                    onTap: () => onTabSelected(1),
                  ),
                ),
                Expanded(
                  child: _ReviewSlot(
                    label: labels.review,
                    tooltip: labels.writeReview,
                    compact: compact,
                    onTap: onReview,
                  ),
                ),
                Expanded(
                  child: _NavTab(
                    activeIcon: Icons.bookmark,
                    inactiveIcon: Icons.bookmark_outline,
                    label: labels.bookmarks,
                    active: currentIndex == 3,
                    compact: compact,
                    onTap: () => onTabSelected(3),
                  ),
                ),
                Expanded(
                  child: _NavTab(
                    activeIcon: Icons.person,
                    inactiveIcon: Icons.person_outline,
                    label: labels.myPage,
                    active: currentIndex == 4,
                    compact: compact,
                    onTap: () => onTabSelected(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One tab slot: filled/outline icon swap + collapsible label. Coral when
/// active, warm-gray when inactive. Shrinks in the compact state.
class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.active,
    required this.compact,
    required this.onTap,
  });

  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final bool active;
  final bool compact;
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
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: compact ? 19 / 21 : 1,
            duration: _navAnim,
            curve: Curves.easeOut,
            child: Icon(
              active ? activeIcon : inactiveIcon,
              size: 21,
              color: color,
            ),
          ),
          _NavLabel(label: label, color: color, bold: active, compact: compact),
        ],
      ),
    );
  }
}

/// Center Review ACTION: a flat coral circle (NOT raised) + white pencil + a
/// coral label. Always coral; never a selected tab.
class _ReviewSlot extends StatelessWidget {
  const _ReviewSlot({
    required this.label,
    required this.tooltip,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: _navAnim,
              curve: Curves.easeOut,
              width: compact ? 30 : 34,
              height: compact ? 30 : 34,
              decoration: const BoxDecoration(
                // Brand-coral LIGHT value in BOTH modes for strong white-icon
                // contrast (not the lighter dark-mode coral).
                color: AppColors.brandCoralLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: AppColors.onPrimary,
                size: 18,
              ),
            ),
            _NavLabel(
              label: label,
              color: c.tabActive,
              bold: false,
              compact: compact,
            ),
          ],
        ),
      ),
    );
  }
}

/// A nav label that collapses (height) + fades out in the compact state.
class _NavLabel extends StatelessWidget {
  const _NavLabel({
    required this.label,
    required this.color,
    required this.bold,
    required this.compact,
  });

  final String label;
  final Color color;
  final bool bold;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: compact ? 0 : 1,
      duration: _navAnim,
      curve: Curves.easeOut,
      child: ClipRect(
        child: AnimatedAlign(
          duration: _navAnim,
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          heightFactor: compact ? 0 : 1,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 10,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
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
    required this.review,
    required this.bookmarks,
    required this.myPage,
    required this.writeReview,
  });

  final String home;
  final String search;

  /// Short label under the center Review action.
  final String review;
  final String bookmarks;
  final String myPage;

  /// Longer accessibility/tooltip phrasing for the Review action.
  final String writeReview;

  static NavLabels of(String code) {
    switch (code) {
      case 'ja':
        return const NavLabels(
          home: 'ホーム',
          search: '検索',
          review: 'レビュー',
          bookmarks: 'ブックマーク',
          myPage: 'マイページ',
          writeReview: 'レビューを書く',
        );
      case 'ko':
        return const NavLabels(
          home: '홈',
          search: '검색',
          review: '리뷰',
          bookmarks: '북마크',
          myPage: '마이페이지',
          writeReview: '리뷰 작성',
        );
      case 'en':
      default:
        return const NavLabels(
          home: 'Home',
          search: 'Search',
          review: 'Review',
          bookmarks: 'Bookmarks',
          myPage: 'My Page',
          writeReview: 'Write a review',
        );
    }
  }
}
