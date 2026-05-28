import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../domain/entities/review_entity.dart';
import '../../../../features/write_review/domain/models/tag_definitions.dart';
import '../../../../presentation/providers/review_providers.dart';
import '../../../../shared/widgets/app_error_kind.dart';
import '../../../../shared/widgets/app_state_labels.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/network_image_fade.dart';
import '../../../../shared/widgets/shimmer_box.dart';

/// "Tabemina Reviews" — first-party reviews stored in Firestore for the
/// current place. Sits above the Google-reviews section on the detail page.
class TabeminaReviewsSection extends ConsumerWidget {
  const TabeminaReviewsSection({
    super.key,
    required this.placeId,
    required this.onWriteReview,
  });

  final String placeId;

  /// Fired by the empty-state CTA — wired by the detail screen to the same
  /// auth-gated write-review flow as the action row / bottom bar.
  final VoidCallback onWriteReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final lang = ref.watch(appLocaleProvider).languageCode;
    final labels = _Labels.of(lang);
    final async = ref.watch(placeReviewsProvider(placeId));

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
                  labels.heading,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                async.maybeWhen(
                  data: (reviews) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${reviews.length}',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: c.primary,
                      ),
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceLg,
            ),
            child: async.when(
              loading: () => const _LoadingState(),
              error: (e, _) => errorStateView(
                context,
                error: e,
                labels: AppStateLabels.of(lang),
                onRetry: () => ref.invalidate(placeReviewsProvider(placeId)),
                compact: true,
              ),
              data: (reviews) {
                if (reviews.isEmpty) {
                  final s = AppStateLabels.of(lang);
                  return EmptyStateView(
                    icon: Icons.chat_bubble_outline_rounded,
                    iconCircleColor: EmptyStateView.coralCircle(context),
                    title: s.emptyDetailReviewsTitle,
                    description: s.emptyDetailReviewsDescription,
                    buttonText: s.emptyDetailReviewsCta,
                    onButtonPressed: onWriteReview,
                    compact: true,
                  );
                }
                return Column(
                  children: [
                    for (final r in reviews)
                      TabeminaReviewCard(review: r, lang: lang),
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

/// Single review row — avatar, name, rating, tags, comment, photos, relative
/// time. Used by [TabeminaReviewsSection].
class TabeminaReviewCard extends StatelessWidget {
  const TabeminaReviewCard({
    super.key,
    required this.review,
    required this.lang,
  });

  final ReviewEntity review;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spaceMd),
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderPrimary, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(
                photoUrl: review.userPhotoUrl,
                fallback: _initialsOf(review.userName),
              ),
              const SizedBox(width: AppConstants.spaceSm),
              Expanded(
                child: Text(
                  review.userName,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formatRelative(review.createdAt, lang),
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Row(
            children: [
              Icon(Icons.star_rounded, size: 14, color: c.secondary),
              const SizedBox(width: 3),
              Text(
                review.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          if (review.moodTags.isNotEmpty || review.priceTags.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spaceSm),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in review.moodTags) _TagChip(label: tagLabel(t, lang)),
                for (final t in review.priceTags) _TagChip(label: tagLabel(t, lang)),
              ],
            ),
          ],
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spaceSm),
            Text(
              review.comment,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                color: c.textPrimary,
                height: 1.4,
              ),
            ),
          ],
          if (review.photoUrls.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spaceSm),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photoUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: FadeInNetworkImage(
                    url: review.photoUrls[i],
                    width: 72,
                    height: 72,
                    errorPlaceholder: Container(
                      width: 72,
                      height: 72,
                      color: c.bgSkeleton,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: c.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _initialsOf(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.fallback});

  final String? photoUrl;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return CircleAvatar(
      radius: 14,
      backgroundColor: c.bgSkeleton,
      backgroundImage:
          (photoUrl != null && photoUrl!.isNotEmpty) ? NetworkImage(photoUrl!) : null,
      child: (photoUrl == null || photoUrl!.isEmpty)
          ? Text(
              fallback,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
                height: 1.0,
              ),
            )
          : null,
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.bgSecondary,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(color: c.borderPrimary, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 11,
          color: c.textSecondary,
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  static const _opacities = [1.0, 0.5];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      children: [
        for (int i = 0; i < _opacities.length; i++)
          Opacity(
            opacity: _opacities[i],
            child: Container(
              margin: const EdgeInsets.only(bottom: AppConstants.spaceMd),
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
                  ShimmerBox(width: double.infinity, height: 11),
                  SizedBox(height: 6),
                  ShimmerBox(width: 220, height: 11),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// "2분 전" / "2 minutes ago" / "2分前" relative time formatter for review
/// timestamps. Falls through to an absolute date once we're past a year so
/// the string doesn't grow indefinitely.
String formatRelative(DateTime when, String lang) {
  final diff = DateTime.now().difference(when);
  if (diff.inSeconds < 60) {
    switch (lang) {
      case 'ja':
        return 'たった今';
      case 'ko':
        return '방금 전';
      default:
        return 'just now';
    }
  }
  if (diff.inMinutes < 60) {
    final n = diff.inMinutes;
    switch (lang) {
      case 'ja':
        return '$n分前';
      case 'ko':
        return '$n분 전';
      default:
        return '${n}m ago';
    }
  }
  if (diff.inHours < 24) {
    final n = diff.inHours;
    switch (lang) {
      case 'ja':
        return '$n時間前';
      case 'ko':
        return '$n시간 전';
      default:
        return '${n}h ago';
    }
  }
  if (diff.inDays < 7) {
    final n = diff.inDays;
    switch (lang) {
      case 'ja':
        return '$n日前';
      case 'ko':
        return '$n일 전';
      default:
        return '${n}d ago';
    }
  }
  if (diff.inDays < 30) {
    final n = diff.inDays ~/ 7;
    switch (lang) {
      case 'ja':
        return '$n週間前';
      case 'ko':
        return '$n주 전';
      default:
        return '${n}w ago';
    }
  }
  if (diff.inDays < 365) {
    final n = diff.inDays ~/ 30;
    switch (lang) {
      case 'ja':
        return '$nヶ月前';
      case 'ko':
        return '$n개월 전';
      default:
        return '${n}mo ago';
    }
  }
  final n = diff.inDays ~/ 365;
  switch (lang) {
    case 'ja':
      return '$n年前';
    case 'ko':
      return '$n년 전';
    default:
      return '${n}y ago';
  }
}

class _Labels {
  const _Labels._({required this.heading});

  final String heading;

  static _Labels of(String lang) {
    switch (lang) {
      case 'ja':
        return const _Labels._(heading: 'Tabeminaレビュー');
      case 'ko':
        return const _Labels._(heading: 'Tabemina 리뷰');
      case 'en':
      default:
        return const _Labels._(heading: 'Tabemina Reviews');
    }
  }
}
