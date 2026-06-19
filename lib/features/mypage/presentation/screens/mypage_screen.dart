import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../../presentation/providers/auth_providers.dart';
import '../../../../presentation/providers/bookmark_providers.dart';
import '../../../../presentation/providers/review_providers.dart';
import '../../../../presentation/widgets/login_bottom_sheet.dart';
import '../../../../shared/widgets/app_error_kind.dart';
import '../../../../shared/widgets/app_state_labels.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../../shared/widgets/tab_scaffold.dart';
import '../mypage_labels.dart';
import '../widgets/review_photo_grid.dart';
import '../widgets/reviews_empty_state.dart';
import '../widgets/stats_row.dart';
import '../widgets/visited_empty_state.dart';

/// My Page — profile/content only: header + stats + tabbed content
/// (reviews / visited). Settings moved to [SettingsScreen], reached via the
/// top-right gear icon.
///
/// The whole page is a single scroll view; the reviews grid shrink-wraps and
/// delegates scrolling to it, so there's no nested-scroll conflict. Stats +
/// tabs only render for a signed-in user (they're all account-scoped); guests
/// see the sign-in prompt.
class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final locale = ref.watch(appLocaleProvider);
    final user = ref.watch(currentUserProvider);
    final lang = locale.languageCode;
    final labels = MyPageLabels.of(lang);

    return Scaffold(
      backgroundColor: c.bgPage,
      appBar: AppBar(
        backgroundColor: c.bgPage,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        // Gear is always available — logged-out users still reach Language /
        // Appearance. tooltip doubles as the accessibility label.
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, size: 24, color: c.textPrimary),
            tooltip: labels.settingsHeader,
            onPressed: () => context.push(AppRoutes.settings),
          ),
          const SizedBox(width: AppConstants.spaceXs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            top: AppConstants.spaceSm,
            bottom: floatingNavContentInset(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (user != null) ...[
                _SignedInHeader(user: user, labels: labels),
                const SizedBox(height: AppConstants.spaceXl),
                _StatsRowConnected(labels: labels),
                const SizedBox(height: AppConstants.spaceXl),
                _TabBar(
                  labels: labels,
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
                _TabContent(tab: _tab, labels: labels),
              ] else
                _GuestSection(labels: labels),
              const SizedBox(height: AppConstants.spaceXl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Watches the two count-bearing providers and renders the stats row.
class _StatsRowConnected extends ConsumerWidget {
  const _StatsRowConnected({required this.labels});

  final MyPageLabels labels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref
        .watch(userReviewsProvider)
        .maybeWhen(data: (list) => list.length, orElse: () => 0);
    final saved = ref
        .watch(bookmarksProvider)
        .maybeWhen(data: (list) => list.length, orElse: () => 0);
    return StatsRow(
      labels: labels,
      reviews: reviews,
      saved: saved,
      visited: 0,
      helpful: 0,
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final MyPageLabels labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // "Saved" lives in the dedicated Bookmarks bottom tab, so it's omitted
    // here to avoid duplication — only My reviews + Visited remain.
    final tabs = [labels.myReviewsTab, labels.visitedTab];
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.borderPrimary, width: 0.5)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++)
            Expanded(
              child: _Tab(
                label: tabs[i],
                active: i == selected,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceMd),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? c.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? c.primary : c.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TabContent extends ConsumerWidget {
  const _TabContent({required this.tab, required this.labels});

  final int tab;
  final MyPageLabels labels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (tab) {
      case 1:
        return _CenteredEmptyArea(child: VisitedEmptyState(labels: labels));
      case 0:
      default:
        return _MyReviewsTab(labels: labels);
    }
  }
}

/// Holds an empty state centered in a generous slice of the screen so the
/// content-only My Page doesn't leave it cramped at the top. Only used for
/// short (empty) states — the reviews grid keeps flowing in the page scroll.
class _CenteredEmptyArea extends StatelessWidget {
  const _CenteredEmptyArea({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      child: Center(child: child),
    );
  }
}

class _MyReviewsTab extends ConsumerWidget {
  const _MyReviewsTab({required this.labels});

  final MyPageLabels labels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLocaleProvider).languageCode;
    final async = ref.watch(userReviewsProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 2),
        child: _GridSkeleton(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceXl),
        child: errorStateView(
          context,
          error: e,
          labels: AppStateLabels.of(lang),
          onRetry: () => ref.invalidate(userReviewsProvider),
          compact: true,
        ),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          final hasDraft = ref
              .watch(hasDraftProvider)
              .maybeWhen(data: (v) => v, orElse: () => false);
          return _CenteredEmptyArea(
            child: ReviewsEmptyState(
              labels: labels,
              hasDraft: hasDraft,
              onWriteReview: () => context.push(AppRoutes.writeReview),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: ReviewPhotoGrid(reviews: reviews),
        );
      },
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => const ShimmerBox(),
    );
  }
}

class _SignedInHeader extends StatelessWidget {
  const _SignedInHeader({required this.user, required this.labels});

  final UserEntity user;
  final MyPageLabels labels;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final photoUrl = user.photoUrl;
    final initials = _initialsOf(user);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: c.bgSkeleton,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    initials,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppConstants.spaceLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName?.isNotEmpty == true
                      ? user.displayName!
                      : labels.fallbackName,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                if (user.email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.email!,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      color: c.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 4),
                // Non-functional for now — placeholder for the v2 profile
                // editor. Rendered in coral so it reads as an action.
                Text(
                  labels.editProfile,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initialsOf(UserEntity user) {
    final name = user.displayName ?? user.email ?? '';
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _GuestSection extends StatelessWidget {
  const _GuestSection({required this.labels});

  final MyPageLabels labels;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: c.bgSkeleton,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 32,
                  color: c.textTertiary,
                ),
              ),
              const SizedBox(width: AppConstants.spaceLg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labels.guestTitle,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels.guestSubtitle,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 13,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceLg),
          _InlineSignInButton(
            label: labels.signIn,
            onTap: () => showLoginBottomSheet(context),
          ),
        ],
      ),
    );
  }
}

class _InlineSignInButton extends StatelessWidget {
  const _InlineSignInButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onPrimary,
          ),
        ),
      ),
    );
  }
}

// Settings rows + sign-out button moved to SettingsScreen
// (lib/features/settings/presentation/screens/settings_screen.dart).
