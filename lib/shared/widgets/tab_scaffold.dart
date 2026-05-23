import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Bottom tab navigation wrapper.
///
/// Hosts the 5 top-level destinations and renders them through a
/// [StatefulNavigationShell] (provided by [StatefulShellRoute.indexedStack]),
/// which keeps each tab's state alive when switching — the same behavior as a
/// plain [IndexedStack], but integrated with GoRouter.
///
/// The center "Review" tab is rendered as a raised, FAB-like action so adding
/// a review reads as the app's primary call to action.
class TabScaffold extends StatelessWidget {
  const TabScaffold({super.key, required this.navigationShell});

  /// The navigation shell driving the indexed stack of tab branches.
  final StatefulNavigationShell navigationShell;

  static const int _reviewIndex = 2;

  void _onTap(int index) {
    // `initialLocation: true` when re-tapping the active tab pops it to root.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: c.bgCard,
        selectedItemColor: c.tabActive,
        unselectedItemColor: c.tabInactive,
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: _ReviewFabIcon(
              active: navigationShell.currentIndex == _reviewIndex,
            ),
            label: 'Review',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            activeIcon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'My Page',
          ),
        ],
      ),
    );
  }
}

/// The distinct, raised "+" action shown in the center tab slot.
class _ReviewFabIcon extends StatelessWidget {
  const _ReviewFabIcon({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: c.primary,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        boxShadow: [
          BoxShadow(
            color: c.primary.withValues(alpha: active ? 0.5 : 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.add, color: AppColors.onPrimary, size: 26),
    );
  }
}
