import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      onTap: () =>
          context.push(AppRoutes.restaurantDetailFor(review.placeId)),
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
    final action =
        await ReviewActionBottomSheet.show(context, review, labels);
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
    try {
      await ref.read(reviewRepositoryProvider).deleteReview(review.reviewId);
      // Refresh the user's grid + the home feed. Detail-page review streams
      // pick up the deletion on their own.
      ref.invalidate(userReviewsProvider);
      ref.invalidate(latestReviewsProvider);
      if (context.mounted) {
        showTabeminaSnackbar(context, message: labels.reviewDeleted);
      }
    } catch (_) {
      if (context.mounted) {
        showTabeminaSnackbar(context, message: labels.reviewDeleteFailed);
      }
    }
  }
}

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
