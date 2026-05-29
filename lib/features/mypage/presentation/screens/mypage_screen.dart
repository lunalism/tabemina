import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/providers/app_theme_mode_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../../../presentation/providers/auth_providers.dart';
import '../../../../presentation/providers/bookmark_providers.dart';
import '../../../../presentation/providers/review_providers.dart';
import '../../../../presentation/widgets/login_bottom_sheet.dart';
import '../../../../shared/widgets/app_error_kind.dart';
import '../../../../shared/widgets/app_state_labels.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../../shared/widgets/tabemina_snackbar.dart';
import '../mypage_labels.dart';
import '../widgets/appearance_selector_modal.dart';
import '../widgets/language_selector_modal.dart';
import '../widgets/review_photo_grid.dart';
import '../widgets/reviews_empty_state.dart';
import '../widgets/stats_row.dart';
import '../widgets/visited_empty_state.dart';

/// My Page — profile header + stats + tabbed content (reviews / saved /
/// visited) + system settings.
///
/// The whole page is a single scroll view; the reviews grid and saved list
/// shrink-wrap and delegate scrolling to it, so there's no nested-scroll
/// conflict. Stats + tabs only render for a signed-in user (they're all
/// account-scoped); guests see the sign-in prompt + settings.
class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends ConsumerState<MyPageScreen> {
  static const String _appVersion = '1.0.0';

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final locale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);
    final user = ref.watch(currentUserProvider);
    final lang = locale.languageCode;
    final labels = MyPageLabels.of(lang);

    return Scaffold(
      backgroundColor: c.bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: AppConstants.spaceXl),
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
              const SizedBox(height: AppConstants.spaceLg),
              Divider(height: 1, thickness: 0.5, color: c.borderPrimary),
              _SectionHeader(label: labels.settingsHeader),
              _SettingRow(
                icon: Icons.language_rounded,
                label: labels.languageLabel,
                trailing: localeDisplayName(locale),
                onTap: () => LanguageSelectorModal.show(context),
              ),
              _SettingRow(
                icon: Icons.brightness_6_outlined,
                label: labels.appearanceLabel,
                trailing: themeModeDisplayName(themeMode, lang),
                onTap: () => AppearanceSelectorModal.show(context),
              ),
              _SettingRow(
                icon: Icons.info_outline_rounded,
                label: labels.versionLabel,
                trailing: _appVersion,
                onTap: null,
              ),
              if (user != null) ...[
                const SizedBox(height: AppConstants.spaceLg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spaceLg,
                  ),
                  child: _SignOutButton(
                    label: labels.signOut,
                    onTap: () => _signOut(context, labels),
                  ),
                ),
              ],
              const SizedBox(height: AppConstants.spaceXl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, MyPageLabels labels) async {
    await ref.read(authRepositoryProvider).signOut();
    if (!context.mounted) return;
    showTabeminaSnackbar(context, message: labels.signedOutSnack);
  }
}

/// Watches the two count-bearing providers and renders the stats row.
class _StatsRowConnected extends ConsumerWidget {
  const _StatsRowConnected({required this.labels});

  final MyPageLabels labels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(userReviewsProvider).maybeWhen(
          data: (list) => list.length,
          orElse: () => 0,
        );
    final saved = ref.watch(bookmarksProvider).maybeWhen(
          data: (list) => list.length,
          orElse: () => 0,
        );
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
        border: Border(
          bottom: BorderSide(color: c.borderPrimary, width: 0.5),
        ),
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
        return VisitedEmptyState(labels: labels);
      case 0:
      default:
        return _MyReviewsTab(labels: labels);
    }
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
          return ReviewsEmptyState(
            labels: labels,
            onWriteReview: () => context.push(AppRoutes.writeReview),
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

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.label, required this.onTap});

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
          border: Border.all(color: c.borderPrimary, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: c.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceXl,
        AppConstants.spaceLg,
        AppConstants.spaceSm,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
          color: c.textSecondary,
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceLg,
          vertical: AppConstants.spaceMd,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c.textPrimary),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 15,
                  color: c.textPrimary,
                ),
              ),
            ),
            Text(
              trailing,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                color: c.textSecondary,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: c.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
