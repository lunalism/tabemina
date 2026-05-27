import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../domain/entities/bookmark_entity.dart';
import '../../../../presentation/providers/bookmark_providers.dart';
import '../../../../presentation/widgets/auth_gate.dart';
import '../../../../shared/widgets/tabemina_snackbar.dart';
import '../../../bookmarks/presentation/bookmarks_labels.dart';
import '../../data/datasources/place_detail_remote_datasource.dart';
import '../../data/models/place_detail.dart';
import '../providers/place_detail_provider.dart';
import '../widgets/action_buttons.dart';
import '../widgets/detail_bottom_bar.dart';
import '../widgets/hero_gallery.dart';
import '../widgets/info_grid.dart';
import '../widgets/info_section.dart';
import '../widgets/mini_map.dart';
import '../widgets/review_card.dart';
import '../widgets/tabemina_reviews_section.dart';

/// Full restaurant detail page — hero gallery, info, action row, info grid,
/// mini map, reviews, fixed bottom bar.
///
/// Driven by the Place Details endpoint; route param is the raw Google Place
/// ID (e.g. `ChIJ...`).
class RestaurantDetailScreen extends ConsumerWidget {
  const RestaurantDetailScreen({super.key, required this.placeId});

  final String placeId;

  static const _expandedHeroHeight = 260.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final async = ref.watch(placeDetailProvider(placeId));
    // Bookmark status drives both the bottom bar icon and the action-row
    // icon. Watching the derived provider here is what makes the heart
    // re-render reactively after a tap.
    final saved = ref.watch(isBookmarkedProvider(placeId));

    return Scaffold(
      backgroundColor: c.bgPage,
      bottomNavigationBar: async.when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
        data: (detail) => DetailBottomBar(
          onWriteReview: () => requireAuth(
            context,
            ref,
            action: () => _openWriteReview(context, detail),
          ),
          onRoute: () => _openExternalUrl(detail.googleMapsUri),
          saved: saved,
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
        error: (_, _) => _ErrorView(
          onRetry: () => ref.invalidate(placeDetailProvider(placeId)),
        ),
        data: (detail) => _DetailContent(
          detail: detail,
          expandedHeight: _expandedHeroHeight,
          saved: saved,
          onSaveToggle: () => requireAuth(
            context,
            ref,
            action: () => _toggleBookmark(context, ref, detail),
          ),
          onWriteReview: () => requireAuth(
            context,
            ref,
            action: () => _openWriteReview(context, detail),
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
    required this.saved,
    required this.onSaveToggle,
    required this.onWriteReview,
  });

  final PlaceDetail detail;
  final double expandedHeight;
  final bool saved;
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
              placeId: detail.id,
              photoNames: detail.photoNames,
              onBack: () => context.pop(),
            ),
          ),
        ),
        SliverToBoxAdapter(child: InfoSection(detail: detail)),
        SliverToBoxAdapter(
          child: ActionButtons(
            onReview: onWriteReview,
            onSave: onSaveToggle,
            onRoute: () => _openExternalUrl(detail.googleMapsUri),
            onShare: () {},
            saved: saved,
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
          child: TabeminaReviewsSection(placeId: detail.id),
        ),
        const SliverToBoxAdapter(child: _ReviewsSection()),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection();

  static const _mockReviews = <DetailReviewData>[
    DetailReviewData(
      initials: 'YT',
      avatarColor: Color(0xFFE8593C),
      name: 'Yuki T.',
      date: '3 days ago',
      rating: 4.5,
      comment:
          'Amazing ramen! The broth was rich and flavorful. Definitely coming back.',
      photoCount: 2,
    ),
    DetailReviewData(
      initials: 'ML',
      avatarColor: Color(0xFF5DCAA5),
      name: 'Mike L.',
      date: '1 week ago',
      rating: 5.0,
      comment:
          'Best tonkatsu I\'ve ever had. Perfectly crispy on the outside, juicy inside.',
      photoCount: 1,
    ),
    DetailReviewData(
      initials: 'さ',
      avatarColor: Color(0xFF85B7EB),
      name: 'さくら',
      date: '2 weeks ago',
      rating: 4.0,
      comment: 'コスパがいい。ランチセットがお得です。',
      photoCount: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spaceLg,
              0,
              AppConstants.spaceLg,
              AppConstants.spaceSm,
            ),
            child: Row(
              children: [
                Text(
                  'Google Reviews',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: c.bgSkeleton,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_mockReviews.length}',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spaceXs,
                      vertical: 2,
                    ),
                    child: Text(
                      'See all >',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: c.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
            child: Column(
              children: [
                for (final r in _mockReviews) DetailReviewCard(data: r),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold({required this.expandedHeight});

  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final statusBar = MediaQuery.paddingOf(context).top;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: expandedHeight,
            child: Stack(
              children: [
                Positioned.fill(child: Container(color: c.bgSkeleton)),
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
              children: [
                _ShimmerBox(width: 220, height: 22, color: c.bgSkeleton),
                const SizedBox(height: AppConstants.spaceSm),
                _ShimmerBox(width: 160, height: 14, color: c.bgSkeleton),
                const SizedBox(height: AppConstants.spaceSm),
                _ShimmerBox(width: 120, height: 14, color: c.bgSkeleton),
                const SizedBox(height: AppConstants.spaceLg),
                Row(
                  children: [
                    for (int i = 0; i < 4; i++) ...[
                      Expanded(
                        child: _ShimmerBox(
                          width: double.infinity,
                          height: 56,
                          color: c.bgSkeleton,
                          radius: 12,
                        ),
                      ),
                      if (i < 3) const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: AppConstants.spaceXl),
                for (int i = 0; i < 4; i++) ...[
                  _ShimmerBox(
                    width: double.infinity,
                    height: 16,
                    color: c.bgSkeleton,
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.color,
    this.radius = 6,
  });

  final double width;
  final double height;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 8,
            child: HeroBackButton(onTap: () => context.pop()),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: c.textTertiary,
                ),
                const SizedBox(height: AppConstants.spaceMd),
                Text(
                  "Couldn't load restaurant details",
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: AppConstants.spaceMd),
                OutlinedButton(
                  onPressed: onRetry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.primary,
                    side: BorderSide(color: c.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusFull,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Toggle the restaurant's bookmark status through the active repo
/// (Firestore when signed in, SharedPreferences when guest) and surface a
/// localized snackbar so the user knows the tap registered.
void _toggleBookmark(BuildContext context, WidgetRef ref, PlaceDetail detail) {
  final repo = ref.read(bookmarkRepositoryProvider);
  final lang = ref.read(appLocaleProvider).languageCode;
  final labels = BookmarksLabels.of(lang);
  final coral = AppColors.of(context).primary;
  final alreadySaved = ref.read(isBookmarkedProvider(detail.id));

  if (alreadySaved) {
    repo.removeBookmark(detail.id);
    showTabeminaSnackbar(
      context,
      message: labels.removedSnack,
      icon: Icons.bookmark_outline_rounded,
    );
  } else {
    repo.addBookmark(BookmarkEntity(
      placeId: detail.id,
      placeName: detail.displayName,
      placeAddress: detail.formattedAddress,
      placeLat: detail.lat,
      placeLng: detail.lng,
      placePhotoUrl: detail.photoNames.isNotEmpty
          ? PlaceDetailRemoteDatasource.photoUrl(detail.photoNames.first)
          : null,
      placeRating: detail.rating,
      userRatingCount: detail.userRatingCount,
      priceLevel: detail.priceLevel,
      primaryType: detail.primaryType,
      savedAt: DateTime.now(),
    ));
    showTabeminaSnackbar(
      context,
      message: labels.savedSnack,
      icon: Icons.bookmark_rounded,
      iconColor: coral,
    );
  }
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
