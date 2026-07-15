import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics_origin.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../domain/entities/review_entity.dart';
import '../../../../features/reporting/presentation/review_actions.dart';
import '../../../../features/restaurant_detail/presentation/widgets/tabemina_reviews_section.dart'
    show formatRelative;
import '../../../../presentation/providers/review_providers.dart';
import '../../../../shared/widgets/app_state_labels.dart';
import '../../../../shared/widgets/network_image_fade.dart';
import '../../../../shared/widgets/shimmer_box.dart';

/// Home-feed "Latest reviews" — vertical stack of the 10 newest Tabemina
/// reviews across all places. Falls back to a soft empty state until users
/// start posting.
class LatestReviewsSection extends ConsumerWidget {
  const LatestReviewsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLocaleProvider).languageCode;
    final labels = _Labels.of(lang);
    final async = ref.watch(visibleLatestReviewsProvider);
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.space2xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(title: labels.heading, seeAll: labels.seeAll),
          const SizedBox(height: AppConstants.spaceSm),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceLg,
            ),
            child: async.when(
              loading: () => const _LoadingList(),
              error: (error, stackTrace) {
                debugPrint(
                  'Latest reviews failed to load: $error\n$stackTrace',
                );
                return _EmptyState(
                  message: labels.errorMessage,
                  retryLabel: AppStateLabels.of(lang).errorNetworkCta,
                  onRetry: () => ref.invalidate(latestReviewsProvider),
                );
              },
              data: (reviews) {
                if (reviews.isEmpty) {
                  return _EmptyState(message: labels.emptyMessage);
                }
                return Column(
                  children: [
                    for (int i = 0; i < reviews.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      _RealReviewCard(review: reviews[i], lang: lang),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.seeAll});

  final String title;
  final String seeAll;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 18, color: c.secondary),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
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
                seeAll,
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
    );
  }
}

/// Inline rebuild of the home review card that talks to live data instead
/// of the old ReviewCardData mock. Kept local to the section so the home
/// feed's tile shape doesn't accidentally lock in shared with the detail
/// card (those two surfaces drift independently over time).
class _RealReviewCard extends ConsumerWidget {
  const _RealReviewCard({required this.review, required this.lang});

  final ReviewEntity review;
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final firstLine = _firstLineOf(review.comment);
    // Author finalized account deletion (B-2-4-2a) — show "Deleted user".
    final deleted = review.isAuthorDeleted;
    final displayName =
        deleted ? AppStateLabels.of(lang).reviewDeletedAuthor : review.userName;
    return InkWell(
      onTap: () => context.push(
        AppRoutes.restaurantDetailFor(review.placeId),
        extra: AnalyticsOrigin.homeFeed,
      ),
      onLongPress: () => showReviewActions(context, ref, review),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.borderPrimary, width: 0.5),
          // Soft warm lift on the off-white page bg (transparent in dark).
          boxShadow: [
            BoxShadow(
              color: c.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spaceMd + 11,
                AppConstants.spaceMd,
                AppConstants.spaceMd,
                AppConstants.spaceMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Avatar(
                        photoUrl: deleted ? null : review.userPhotoUrl,
                        fallback: deleted ? '?' : _initialsOf(review.userName),
                      ),
                      const SizedBox(width: AppConstants.spaceSm),
                      Expanded(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontStyle:
                                deleted ? FontStyle.italic : FontStyle.normal,
                            color: deleted ? c.textSecondary : c.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        formatRelative(review.createdAt, lang),
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 10,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (review.photoUrls.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.spaceSm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: FadeInNetworkImage(
                        url: review.photoUrls.first,
                        width: 90,
                        height: 68,
                      ),
                    ),
                  ],
                  if (firstLine.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.spaceSm),
                    Text(
                      '"$firstLine"',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        color: c.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppConstants.spaceSm),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 12, color: c.primary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          review.placeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 11,
                            color: c.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.star_rounded,
                        size: 11,
                        color: c.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        review.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 11,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: AppConstants.spaceMd,
              top: 8,
              bottom: 8,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _firstLineOf(String text) {
    final t = text.trim();
    if (t.isEmpty) return '';
    final nl = t.indexOf('\n');
    return nl < 0 ? t : t.substring(0, nl);
  }

  String _initialsOf(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _Avatar extends StatefulWidget {
  const _Avatar({required this.photoUrl, required this.fallback});

  final String? photoUrl;
  final String fallback;

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> {
  /// Set when the network image fails to load (e.g. a stale googleusercontent
  /// URL 404s) so the initials fallback replaces the blank circle.
  bool _failed = false;

  @override
  void didUpdateWidget(_Avatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.photoUrl != oldWidget.photoUrl) _failed = false;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final url = widget.photoUrl;
    final showImage = !_failed && url != null && url.isNotEmpty;
    return CircleAvatar(
      radius: 14,
      backgroundColor: c.bgSkeleton,
      backgroundImage: showImage ? NetworkImage(url) : null,
      onBackgroundImageError: showImage
          ? (_, _) {
              if (mounted) setState(() => _failed = true);
            }
          : null,
      child: showImage
          ? null
          : Text(
              widget.fallback,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
                height: 1.0,
              ),
            ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  // Two cards with a fade-out tail; matches the layout of
  // [_RealReviewCard] above so the resolve transition doesn't reflow
  // the surrounding feed.
  static const _opacities = [1.0, 0.5];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      children: [
        for (int i = 0; i < _opacities.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Opacity(
            opacity: _opacities[i],
            child: Container(
              decoration: BoxDecoration(
                color: c.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.borderPrimary, width: 0.5),
              ),
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spaceMd + 11,
                AppConstants.spaceMd,
                AppConstants.spaceMd,
                AppConstants.spaceMd,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShimmerCircle(size: 24),
                      SizedBox(width: AppConstants.spaceSm),
                      ShimmerBox(width: 80, height: 10),
                      Spacer(),
                      ShimmerBox(width: 50, height: 10),
                    ],
                  ),
                  SizedBox(height: AppConstants.spaceSm),
                  ShimmerBox(width: 90, height: 68, borderRadius: 10),
                  SizedBox(height: AppConstants.spaceSm),
                  ShimmerBox(width: double.infinity, height: 10),
                  SizedBox(height: 6),
                  ShimmerBox(width: 200, height: 10),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Passive card for the no-reviews and error cases. When [onRetry] is
/// provided (error only), a Retry pill renders below the message — styled to
/// match the cafe section's error state so the two Home-feed retries read
/// identically. The plain empty state stays a single message row.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, this.retryLabel, this.onRetry});

  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceLg,
        vertical: AppConstants.spaceLg,
      ),
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderPrimary, width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 20,
                color: c.textTertiary,
              ),
              const SizedBox(width: AppConstants.spaceMd),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    color: c.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppConstants.spaceSm),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: c.primary,
                side: BorderSide(color: c.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
              ),
              child: Text(
                retryLabel ?? '',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Labels {
  const _Labels._({
    required this.heading,
    required this.seeAll,
    required this.emptyMessage,
    required this.errorMessage,
  });

  final String heading;
  final String seeAll;
  final String emptyMessage;
  final String errorMessage;

  static _Labels of(String lang) {
    switch (lang) {
      case 'ja':
        return const _Labels._(
          heading: '最新のレビュー',
          seeAll: 'すべて表示 >',
          emptyMessage: 'まだレビューはありません。最初のレビューを書いてみよう!',
          errorMessage: 'レビューを読み込めませんでした。',
        );
      case 'ko':
        return const _Labels._(
          heading: '최신 리뷰',
          seeAll: '모두 보기 >',
          emptyMessage: '아직 리뷰가 없습니다. 첫 번째 리뷰를 작성해보세요!',
          errorMessage: '리뷰를 불러올 수 없습니다.',
        );
      case 'en':
      default:
        return const _Labels._(
          heading: 'Latest reviews',
          seeAll: 'See all >',
          emptyMessage: 'No reviews yet. Be the first to review!',
          errorMessage: "Couldn't load reviews.",
        );
    }
  }
}
