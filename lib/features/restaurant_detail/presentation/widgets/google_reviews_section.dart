import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../shared/widgets/initials_avatar.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = ref.watch(appLocaleProvider).languageCode;
    final labels = _Labels.of(lang);

    // Google text-attribution spec: weight 400, 12–16sp, color white / #1F1F1F
    // / #5E5E5E, contrast ≥ 4.5:1. We use #5E5E5E on the light surface and pure
    // white on the dark surface so both clear 4.5:1; "Google Maps" is never
    // bold, never localized, never restyled beyond this.
    final attributionColor =
        isDark ? Colors.white : const Color(0xFF5E5E5E);

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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Attribution: the unmodified text "Google Maps" rendered to
                // Google's text-attribution spec — weight 400, ~14sp, neutral
                // gray/white, single line, Latin, NOT localized. The a11y label
                // names the source explicitly.
                Semantics(
                  label: 'Google Maps',
                  child: Text(
                    'Google Maps',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: attributionColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Localized descriptor word in the app's normal heading style.
                Text(
                  labels.descriptor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
                  _GoogleReviewCard(
                    review: r,
                    lang: lang,
                    onAuthorTap: onAuthorTap,
                  ),
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
///
/// When Google auto-translated the body ([GoogleReview.isTranslated]), the card
/// shows a subtle "Translated by Google" caption and a "See original" toggle
/// that swaps to the author's original words (and back). Stateful purely for
/// that per-card toggle — nothing is persisted.
class _GoogleReviewCard extends StatefulWidget {
  const _GoogleReviewCard({
    required this.review,
    required this.lang,
    required this.onAuthorTap,
  });

  final GoogleReview review;
  final String lang;
  final ValueChanged<String?> onAuthorTap;

  @override
  State<_GoogleReviewCard> createState() => _GoogleReviewCardState();
}

class _GoogleReviewCardState extends State<_GoogleReviewCard> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final review = widget.review;
    final labels = _Labels.of(widget.lang);
    final hasProfile = review.authorUri != null && review.authorUri!.isNotEmpty;
    final translated = review.isTranslated;
    // Default to the shown (translated) text; the toggle swaps to the original.
    final body = (translated && _showOriginal) ? review.originalText! : review.text;

    final header = Row(
      children: [
        InitialsAvatar(
          photoUrl: review.authorPhotoUri,
          fallback: initialsOf(review.authorName),
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
              onTap: () => widget.onAuthorTap(review.authorUri),
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
          if (body.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spaceSm),
            Text(
              body,
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
          // Auto-translation disclosure + toggle. Text labels only (never
          // color-alone). "Google" stays Latin in the caption.
          if (translated) ...[
            const SizedBox(height: AppConstants.spaceSm),
            Row(
              children: [
                if (!_showOriginal) ...[
                  Text(
                    labels.translatedByGoogle,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 11,
                      color: c.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                InkWell(
                  onTap: () => setState(() => _showOriginal = !_showOriginal),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      _showOriginal
                          ? labels.showTranslation
                          : labels.seeOriginal,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: c.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

}

/// Localized copy (KO / JA / EN). The brand tokens "Google Maps" / "Google"
/// stay unmodified Latin script in every language — only the surrounding words
/// are translated, per Google's brand policy.
class _Labels {
  const _Labels._({
    required this.descriptor,
    required this.translatedByGoogle,
    required this.seeOriginal,
    required this.showTranslation,
  });

  /// The word that follows the "Google Maps" attribution in the section header.
  final String descriptor;

  /// Caption shown under an auto-translated review body ("Google" stays Latin).
  final String translatedByGoogle;

  /// Toggle → swap to the author's original-language text.
  final String seeOriginal;

  /// Toggle → swap back to the Google translation.
  final String showTranslation;

  static _Labels of(String lang) {
    switch (lang) {
      case 'ja':
        return const _Labels._(
          descriptor: 'のレビュー',
          translatedByGoogle: 'Google による翻訳',
          seeOriginal: '原文を表示',
          showTranslation: '翻訳を表示',
        );
      case 'ko':
        return const _Labels._(
          descriptor: '리뷰',
          translatedByGoogle: 'Google 번역',
          seeOriginal: '원문 보기',
          showTranslation: '번역 보기',
        );
      case 'en':
      default:
        return const _Labels._(
          descriptor: 'reviews',
          translatedByGoogle: 'Translated by Google',
          seeOriginal: 'See original',
          showTranslation: 'Show translation',
        );
    }
  }
}
