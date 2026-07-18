import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/analytics/analytics_origin.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/analytics_providers.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../domain/entities/bookmark_entity.dart';
import '../../../../presentation/providers/bookmark_providers.dart';
import '../../../../presentation/providers/review_providers.dart';
import '../../../../presentation/widgets/auth_gate.dart';
import '../../../../shared/widgets/app_error_kind.dart';
import '../../../../shared/widgets/app_state_labels.dart';
import '../../../../shared/widgets/cooldown_labels.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../../shared/widgets/tabemina_snackbar.dart';
import '../../../bookmarks/presentation/bookmarks_labels.dart';
import '../../data/datasources/place_detail_remote_datasource.dart';
import '../../data/models/place_detail.dart';
import '../detail_labels.dart';
import '../providers/place_detail_provider.dart';
import '../providers/restaurant_viewed_provider.dart';
import '../widgets/action_buttons.dart';
import '../widgets/detail_bottom_bar.dart';
import '../widgets/hero_gallery.dart';
import '../widgets/info_grid.dart';
import '../widgets/info_section.dart';
import '../widgets/google_reviews_section.dart';
import '../widgets/mini_map.dart';
import '../widgets/tabemina_reviews_section.dart';

/// Full restaurant detail page — hero gallery, info, action row, info grid,
/// mini map, reviews, fixed bottom bar.
///
/// Driven by the Place Details endpoint; route param is the raw Google Place
/// ID (e.g. `ChIJ...`). [origin] is the surface this page was opened from,
/// resolved from the route extra (defaults to [AnalyticsOrigin.deepLink]).
class RestaurantDetailScreen extends ConsumerWidget {
  const RestaurantDetailScreen({
    super.key,
    required this.placeId,
    this.origin = AnalyticsOrigin.deepLink,
  });

  final String placeId;
  final AnalyticsOrigin origin;

  static const _expandedHeroHeight = 260.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    // One-shot analytics for opening this restaurant (id + origin, no PII).
    ref.watch(restaurantViewedTrackerProvider((placeId: placeId, origin: origin)));
    final async = ref.watch(placeDetailProvider(placeId));
    // We do *not* watch isBookmarkedProvider at this level on purpose:
    // a bookmark toggle should rebuild only the two bookmark icons (one
    // in the bottom bar, one in the action row), never this scaffold or
    // its CustomScrollView. The icons watch the provider themselves
    // inside the bottom bar / action buttons widgets.

    return Scaffold(
      backgroundColor: c.bgPage,
      bottomNavigationBar: async.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (detail) => DetailBottomBar(
          placeId: detail.id,
          onWriteReview: () => requireAuth(
            context,
            ref,
            action: () => _writeReviewOrCooldown(context, ref, detail),
          ),
          onRoute: () => _openExternalUrl(detail.googleMapsUri),
          onSaveToggle: () => requireAuth(
            context,
            ref,
            action: () => _toggleBookmark(context, ref, detail),
          ),
        ),
      ),
      body: async.when(
        loading: () => const _LoadingScaffold(
          expandedHeight: _expandedHeroHeight,
        ),
        error: (e, _) => _ErrorView(
          error: e,
          onRetry: () => ref.invalidate(placeDetailProvider(placeId)),
        ),
        data: (detail) => _DetailContent(
          detail: detail,
          expandedHeight: _expandedHeroHeight,
          onSaveToggle: () => requireAuth(
            context,
            ref,
            action: () => _toggleBookmark(context, ref, detail),
          ),
          onWriteReview: () => requireAuth(
            context,
            ref,
            action: () => _writeReviewOrCooldown(context, ref, detail),
          ),
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.detail,
    required this.expandedHeight,
    required this.onSaveToggle,
    required this.onWriteReview,
  });

  final PlaceDetail detail;
  final double expandedHeight;
  final VoidCallback onSaveToggle;
  final VoidCallback onWriteReview;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: expandedHeight,
            child: HeroGallery(
              photoNames: detail.photoNames,
              onBack: () => context.pop(),
            ),
          ),
        ),
        SliverToBoxAdapter(child: InfoSection(detail: detail)),
        SliverToBoxAdapter(
          child: ActionButtons(
            placeId: detail.id,
            onReview: onWriteReview,
            onSave: onSaveToggle,
            onRoute: () => _openExternalUrl(detail.googleMapsUri),
            onShare: () {},
          ),
        ),
        SliverToBoxAdapter(
          child: InfoGrid(
            detail: detail,
            onPhoneTap: (phone) => _openExternalUrl('tel:$phone'),
            onWebsiteTap: (url) => _openExternalUrl(url),
          ),
        ),
        if (detail.lat != null && detail.lng != null)
          SliverToBoxAdapter(
            child: MiniMap(
              lat: detail.lat!,
              lng: detail.lng!,
              placeId: detail.id,
              onTap: () => _openExternalUrl(detail.googleMapsUri),
            ),
          ),
        SliverToBoxAdapter(
          child: TabeminaReviewsSection(
            placeId: detail.id,
            onWriteReview: onWriteReview,
          ),
        ),
        SliverToBoxAdapter(
          child: GoogleReviewsSection(
            reviews: detail.reviews,
            onAuthorTap: _openExternalUrl,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({required this.expandedHeight});

  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    final statusBar = MediaQuery.paddingOf(context).top;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: expandedHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ShimmerBox(
                    width: double.infinity,
                    height: expandedHeight,
                  ),
                ),
                Positioned(
                  top: statusBar + 8,
                  left: 8,
                  child: HeroBackButton(onTap: () => context.pop()),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 200, height: 16),
                SizedBox(height: 6),
                ShimmerBox(width: 260, height: 12),
                SizedBox(height: AppConstants.spaceLg),
                _ActionButtonsSkeletonRow(),
                SizedBox(height: AppConstants.spaceLg),
                ShimmerBox(width: 80, height: 12),
                SizedBox(height: AppConstants.spaceSm),
                ShimmerBox(width: double.infinity, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: double.infinity, height: 14),
                SizedBox(height: 6),
                ShimmerBox(width: 220, height: 14),
                SizedBox(height: AppConstants.spaceLg),
                ShimmerBox(width: double.infinity, height: 140, borderRadius: 12),
                SizedBox(height: AppConstants.spaceLg),
                ShimmerBox(width: 70, height: 12),
                SizedBox(height: AppConstants.spaceSm),
                _ReviewSkeletonCard(opacity: 1.0),
                SizedBox(height: AppConstants.spaceSm),
                _ReviewSkeletonCard(opacity: 0.5),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 4-up action button row (Review / Save / Route / Share) skeleton row,
/// matched to the [ActionButtons] component's 56-tall rounded tiles.
class _ActionButtonsSkeletonRow extends StatelessWidget {
  const _ActionButtonsSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: ShimmerBox(height: 44, borderRadius: 10)),
        SizedBox(width: 8),
        Expanded(child: ShimmerBox(height: 44, borderRadius: 10)),
        SizedBox(width: 8),
        Expanded(child: ShimmerBox(height: 44, borderRadius: 10)),
        SizedBox(width: 8),
        Expanded(child: ShimmerBox(height: 44, borderRadius: 10)),
      ],
    );
  }
}

/// Inline review card skeleton — mirrors the layout of a real review
/// card so the resolve transition doesn't reflow the surrounding stack.
class _ReviewSkeletonCard extends StatelessWidget {
  const _ReviewSkeletonCard({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spaceMd),
        decoration: BoxDecoration(
          color: c.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.borderPrimary, width: 0.5),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerCircle(size: 28),
                SizedBox(width: AppConstants.spaceSm),
                ShimmerBox(width: 100, height: 11),
                Spacer(),
                ShimmerBox(width: 50, height: 10),
              ],
            ),
            SizedBox(height: AppConstants.spaceSm),
            ShimmerBox(width: 60, height: 12),
            SizedBox(height: AppConstants.spaceSm),
            ShimmerBox(width: double.infinity, height: 60, borderRadius: 8),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLocaleProvider).languageCode;
    // A deleted place (Places 404) is permanent — a retry can never succeed,
    // so that kind gets a "no longer available" state whose only action is
    // going back, instead of the generic retriable error view.
    final Widget stateView;
    if (classifyError(error) == AppErrorKind.notFound) {
      final labels = DetailLabels.of(lang);
      stateView = EmptyStateView(
        icon: Icons.storefront_outlined,
        iconCircleColor: EmptyStateView.grayCircle(context),
        title: labels.notFoundTitle,
        description: labels.notFoundDescription,
        buttonText: labels.notFoundBack,
        onButtonPressed: () => context.pop(),
      );
    } else {
      stateView = errorStateView(
        context,
        error: error,
        labels: AppStateLabels.of(lang),
        onRetry: onRetry,
      );
    }
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 8,
            child: HeroBackButton(onTap: () => context.pop()),
          ),
          Center(child: stateView),
        ],
      ),
    );
  }
}

/// Toggle the restaurant's bookmark status through the active repo
/// (Firestore when signed in, SharedPreferences when guest) and surface a
/// localized snackbar so the user knows the tap registered.
Future<void> _toggleBookmark(
  BuildContext context,
  WidgetRef ref,
  PlaceDetail detail,
) async {
  final repo = ref.read(bookmarkRepositoryProvider);
  final analytics = ref.read(analyticsEventsProvider);
  final lang = ref.read(appLocaleProvider).languageCode;
  final labels = BookmarksLabels.of(lang);
  final coral = AppColors.of(context).primary;
  final alreadySaved = ref.read(isBookmarkedProvider(detail.id));

  if (alreadySaved) {
    showTabeminaSnackbar(
      context,
      message: labels.removedSnack,
      icon: Icons.bookmark_outline_rounded,
    );
    await repo.removeBookmark(detail.id);
    // Surface-where-the-action-happened: this toggle lives on the detail page.
    analytics.bookmarkRemoved(
      restaurantId: detail.id,
      origin: AnalyticsOrigin.restaurantDetail,
    );
  } else {
    showTabeminaSnackbar(
      context,
      message: labels.savedSnack,
      icon: Icons.bookmark_rounded,
      iconColor: coral,
    );
    await repo.addBookmark(BookmarkEntity(
      placeId: detail.id,
      placeName: detail.displayName,
      placeAddress: detail.formattedAddress,
      placeLat: detail.lat,
      placeLng: detail.lng,
      // Store the bare Places photo *resource name* (e.g. places/ID/photos/REF),
      // NOT a full media URL — the display URL is rebuilt with the CURRENT key
      // at render time, so a key rotation can't strand a dead ?key= in saved
      // bookmarks. Field name stays 'placePhotoUrl' to avoid a schema migration.
      placePhotoUrl: detail.photoNames.isNotEmpty
          ? detail.photoNames.first
          : null,
      placeRating: detail.rating,
      userRatingCount: detail.userRatingCount,
      priceLevel: detail.priceLevel,
      primaryType: detail.primaryType,
      savedAt: DateTime.now(),
    ));
    analytics.bookmarkAdded(
      restaurantId: detail.id,
      origin: AnalyticsOrigin.restaurantDetail,
    );
  }
}

/// Gate the write-review entry on the 24h per-place cooldown. If the user
/// reviewed this place within 24h, show an explanatory dialog instead of
/// navigating to a form they can't submit.
Future<void> _writeReviewOrCooldown(
  BuildContext context,
  WidgetRef ref,
  PlaceDetail detail,
) async {
  final remaining =
      await ref.read(reviewCooldownRemainingProvider(detail.id).future);
  if (!context.mounted) return;
  if (remaining != null) {
    final lang = ref.read(appLocaleProvider).languageCode;
    await _showCooldownDialog(context, lang, remaining);
    return;
  }
  _openWriteReview(context, detail);
}

Future<void> _showCooldownDialog(
  BuildContext context,
  String lang,
  Duration remaining,
) {
  final labels = CooldownLabels.of(lang);
  final c = AppColors.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        labels.title,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
        ),
      ),
      content: Text(
        labels.detail(remaining),
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          color: c.textSecondary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'OK',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              color: c.primary,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Hand off to the write-review modal, carrying just enough restaurant
/// context that the form can render the mini header without re-fetching the
/// full Place Detail.
void _openWriteReview(BuildContext context, PlaceDetail detail) {
  context.push(AppRoutes.writeReview, extra: {
    'placeId': detail.id,
    'name': detail.displayName,
    'primaryType': detail.primaryType,
    'photoUrl': detail.photoNames.isNotEmpty
        ? PlaceDetailRemoteDatasource.photoUrl(detail.photoNames.first)
        : null,
  });
}

/// Open an external URL via the OS handler. Swallowing failures here is
/// intentional — the user already tapped, and there is no useful recovery if
/// the OS rejects the URL (no installed handler, malformed scheme). A snack
/// would just nag them.
Future<void> _openExternalUrl(String? url) async {
  if (url == null || url.isEmpty) return;
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
