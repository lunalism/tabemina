import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../presentation/widgets/auth_gate.dart';

/// Bottom tab navigation wrapper.
///
/// Hosts the 5 top-level destinations and renders them through a
/// [StatefulNavigationShell] (provided by [StatefulShellRoute.indexedStack]),
/// which keeps each tab's state alive when switching — the same behavior as a
/// plain [IndexedStack], but integrated with GoRouter.
///
/// The center "Review" tab is rendered as a raised, FAB-like action so adding
/// a review reads as the app's primary call to action.
class TabScaffold extends ConsumerWidget {
  const TabScaffold({super.key, required this.navigationShell});

  /// The navigation shell driving the indexed stack of tab branches.
  final StatefulNavigationShell navigationShell;

  static const int _reviewIndex = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);

    // The Review tab is special: tapping it shouldn't switch branches but
    // instead push the write-review modal over the current tab. This keeps
    // the user's place in the underlying tab when the modal is dismissed.
    // Writing a review requires auth — gate behind the login sheet first.
    void onTap(int index) {
      if (index == _reviewIndex) {
        requireAuth(
          context,
          ref,
          action: () => context.push(AppRoutes.writeReview),
        );
        return;
      }
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: c.bgCard,
        selectedItemColor: c.tabActive,
        unselectedItemColor: c.tabInactive,
        showUnselectedLabels: true,
        iconSize: 24,
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
///
/// The 40×40 raised square is bigger than [BottomNavigationBar]'s 24px icon
/// slot — left unmanaged it stretches the whole bar. Anchoring it inside a
/// 24-tall [SizedBox] with an [OverflowBox] keeps the bar at its intrinsic
/// height while letting the FAB render at its full visual size.
///
/// [Alignment.bottomCenter] on the OverflowBox pins the FAB's bottom to the
/// icon-slot bottom so it extends *only upward* — without that the default
/// `center` alignment let the FAB spill 8px below the slot and crash into
/// the "Review" label. A small extra translate gives the label 4-6px of
/// breathing room.
class _ReviewFabIcon extends StatelessWidget {
  const _ReviewFabIcon({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox(
      width: 24,
      height: 24,
      child: OverflowBox(
        maxWidth: 40,
        maxHeight: 40,
        alignment: Alignment.bottomCenter,
        child: Transform.translate(
          offset: const Offset(0, -4),
          child: Container(
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
          ),
        ),
      ),
    );
  }
}
