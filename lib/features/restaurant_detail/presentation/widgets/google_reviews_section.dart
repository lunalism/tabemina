import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../data/models/place_detail.dart';

/// SECONDARY "Google Maps reviews" section on the detail page — live Google
/// review content shown beneath the primary Tabemina reviews.
///
/// COMPLIANCE: attribution is the unmodified text "Google Maps" (Google forbids
/// recreating/modifying its logo, and the brand name must never be localized or
/// restyled — so only the surrounding word is translated). Review content is
/// never cached or persisted: it arrives with the in-memory [PlaceDetail] for
/// this screen only and is dropped when the screen closes. Each card renders
/// the required author attribution (name, a tappable link to the author's
/// Google profile, and their avatar), and the review body is plain text only
/// (see [sanitizeReviewText]) — no HTML.
class GoogleReviewsSection extends ConsumerWidget {
  const GoogleReviewsSection({
    super.key,
    required this.reviews,
    required this.onAuthorTap,
  });

  final List<GoogleReview> reviews;

  /// Opens the author's Google profile URL in the external browser.
  final ValueChanged<String?> onAuthorTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Nothing to show → render nothing (never a broken/empty-looking section).
    // Offline / error never reach here: reviews ride along with the place-detail
    // call, so a failed fetch shows the screen-level error view instead.
    if (reviews.isEmpty) return const SizedBox.shrink();

    final c = AppColors.of(context);
    final lang = ref.watch(appLocaleProvider).languageCode;
    final labels = _Labels.of(lang);

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
                // Attribution: the unmodified text "Google Maps" (no logo, never
                // localized/restyled) embedded in the localized title. The
                // a11y label names the source explicitly.
                Semantics(
                  label: 'Google Maps',
                  child: Text(
                    labels.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
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
                    '${reviews.length}',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceLg,
            ),
            child: Column(
              children: [
                for (final r in reviews)
                  _GoogleReviewCard(review: r, onAuthorTap: onAuthorTap),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One Google review row — avatar + name (tappable → profile) + star rating +
/// relative time + plain-text body. No photos (the API exposes none per review).
class _GoogleReviewCard extends StatelessWidget {
  const _GoogleReviewCard({required this.review, required this.onAuthorTap});

  final GoogleReview review;
  final ValueChanged<String?> onAuthorTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hasProfile = review.authorUri != null && review.authorUri!.isNotEmpty;

    final header = Row(
      children: [
        _Avatar(
          photoUrl: review.authorPhotoUri,
          fallback: _initialOf(review.authorName),
        ),
        const SizedBox(width: AppConstants.spaceSm),
        Expanded(
          child: Text(
            review.authorName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              // Link affordance when a profile URL is present.
              color: hasProfile ? c.primary : c.textPrimary,
            ),
          ),
        ),
        if (review.relativeTime != null && review.relativeTime!.isNotEmpty)
          Text(
            review.relativeTime!,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              color: c.textSecondary,
            ),
          ),
      ],
    );

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
          // Tapping the avatar + name opens the author's Google profile (the
          // required attribution link). Inert when the API gives no URL.
          if (hasProfile)
            InkWell(
              onTap: () => onAuthorTap(review.authorUri),
              borderRadius: BorderRadius.circular(8),
              child: header,
            )
          else
            header,
          if (review.rating > 0) ...[
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
          ],
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spaceSm),
            Text(
              review.text,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                color: c.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _initialOf(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t.characters.first.toUpperCase();
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl, required this.fallback});

  final String? photoUrl;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return CircleAvatar(
      radius: 14,
      backgroundColor: c.bgSkeleton,
      backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              fallback,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
                height: 1.0,
              ),
            ),
    );
  }
}

/// Localized section title (KO / JA / EN). The attribution "Google Maps" stays
/// unmodified Latin script in every language — only the surrounding word is
/// translated, per Google's brand policy.
class _Labels {
  const _Labels._({required this.title});

  final String title;

  static _Labels of(String lang) {
    switch (lang) {
      case 'ja':
        return const _Labels._(title: 'Google Maps のレビュー');
      case 'ko':
        return const _Labels._(title: 'Google Maps 리뷰');
      case 'en':
      default:
        return const _Labels._(title: 'Google Maps reviews');
    }
  }
}
