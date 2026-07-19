import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics_origin.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../domain/entities/review_entity.dart';
import '../../../../presentation/providers/review_providers.dart';
import '../../../../shared/widgets/network_image_fade.dart';
import '../../../../shared/widgets/tabemina_snackbar.dart';
import '../mypage_labels.dart';
import 'delete_review_dialog.dart';
import 'review_action_bottom_sheet.dart';

/// Instagram-style 3-column grid of the user's reviews, cover photo first,
/// newest first. Tapping a cell opens that review's restaurant detail page.
///
/// Embedded inside the My Page scroll view, so the grid shrink-wraps and
/// delegates scrolling to its parent (no nested scroll conflict).
class ReviewPhotoGrid extends StatelessWidget {
  const ReviewPhotoGrid({super.key, required this.reviews});

  final List<ReviewEntity> reviews;

  @override
  Widget build(BuildContext context) {
    // Defensive copy + sort newest-first (the repo query already orders by
    // createdAt desc, but sorting here keeps the grid correct regardless of
    // source ordering).
    final sorted = [...reviews]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
      itemCount: sorted.length,
      itemBuilder: (context, i) => _ReviewCell(review: sorted[i]),
    );
  }
}

class _ReviewCell extends ConsumerWidget {
  const _ReviewCell({required this.review});

  final ReviewEntity review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final photo = review.photoUrls.isNotEmpty ? review.photoUrls.first : null;
    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.restaurantDetailFor(review.placeId),
        extra: AnalyticsOrigin.myPage,
      ),
      onLongPress: () => _onLongPress(context, ref),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photo != null)
            FadeInNetworkImage(
              url: photo,
              errorPlaceholder: const _Placeholder(),
            )
          else
            const _Placeholder(),
          // Hidden-by-reports: dim the cell and tag it so the author knows it
          // was removed from public listings (it still shows here, only here).
          if (review.isHidden) ...[
            Positioned.fill(
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
            ),
            Positioned(
              left: 4,
              top: 4,
              child: _HiddenBadge(
                label: MyPageLabels.of(
                  ref.watch(appLocaleProvider).languageCode,
                ).underReview,
              ),
            ),
          ],
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '★ ${review.rating.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onLongPress(BuildContext context, WidgetRef ref) async {
    final labels = MyPageLabels.of(ref.read(appLocaleProvider).languageCode);
    final action = await ReviewActionBottomSheet.show(context, review, labels);
    if (action == null || !context.mounted) return;

    switch (action) {
      case ReviewAction.edit:
        context.push(AppRoutes.editReview, extra: review);
      case ReviewAction.delete:
        final confirmed = await DeleteReviewDialog.show(context, labels);
        if (confirmed != true || !context.mounted) return;
        await _delete(context, ref, labels);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    MyPageLabels labels,
  ) async {
    // File-scoped guard (this cell is a stateless ConsumerWidget, so the
    // flag can't live on the instance): a second confirm while a delete is
    // in flight is a no-op. The modal barrier below blocks same-screen taps
    // for the duration anyway.
    if (_isDeletingReview) return;
    _isDeletingReview = true;
    // Blocking barrier + spinner for the duration of the delete (Storage
    // photos go first, sequentially — seconds on a slow network).
    // PopScope(canPop: false): barrierDismissible only stops barrier taps,
    // not the Android system Back action. The dialog's own context is
    // retained so dismissal can only ever pop the spinner route itself,
    // never an unrelated route underneath.
    BuildContext? dialogContext;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return const PopScope(
          canPop: false,
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
    var failed = false;
    try {
      await ref.read(reviewRepositoryProvider).deleteReview(review.reviewId);
    } catch (_) {
      failed = true;
    } finally {
      _isDeletingReview = false;
      // Pop the spinner barrier before any snackbar goes up.
      final ctx = dialogContext;
      if (ctx != null && ctx.mounted) {
        Navigator.of(ctx).pop();
      }
    }
    if (!failed) {
      // Refresh the user's grid + the home feed. Detail-page review streams
      // pick up the deletion on their own.
      ref.invalidate(userReviewsProvider);
      ref.invalidate(latestReviewsProvider);
    }
    if (context.mounted) {
      showTabeminaSnackbar(
        context,
        message: failed ? labels.reviewDeleteFailed : labels.reviewDeleted,
      );
    }
  }
}

/// In-flight guard for [_ReviewCell._delete]. See the comment at the check
/// site; Firestore's delete is idempotent so this is belt-and-braces against
/// double invocation, not a correctness requirement.
bool _isDeletingReview = false;

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      color: c.bgSkeleton,
      alignment: Alignment.center,
      child: Icon(Icons.restaurant, size: 24, color: c.textTertiary),
    );
  }
}

/// Small "Under review" chip on a hidden own-review cell. Icon + label so the
/// state reads without relying on the dimming scrim alone.
class _HiddenBadge extends StatelessWidget {
  const _HiddenBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.visibility_off_outlined,
            size: 10,
            color: Colors.white,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
