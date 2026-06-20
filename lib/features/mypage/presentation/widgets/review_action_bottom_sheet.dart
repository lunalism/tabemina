import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../domain/entities/review_entity.dart';
import '../../../../shared/widgets/network_image_fade.dart';
import '../mypage_labels.dart';

/// What the user chose in the review long-press menu.
enum ReviewAction { edit, delete }

/// Long-press action sheet for a review thumbnail: a context preview plus
/// Edit / Delete options. Returns the chosen [ReviewAction], or null if the
/// user cancelled / tapped outside.
class ReviewActionBottomSheet {
  static Future<ReviewAction?> show(
    BuildContext context,
    ReviewEntity review,
    MyPageLabels labels,
  ) {
    return showModalBottomSheet<ReviewAction>(
      context: context,
      // Root navigator so the sheet layers above the floating nav bar when the
      // review is long-pressed from a shell tab (Home feed / My Page).
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _Sheet(review: review, labels: labels),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.review, required this.labels});

  final ReviewEntity review;
  final MyPageLabels labels;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final danger = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFF07070)
        : const Color(0xFFE24B4A);
    final cover = review.photoUrls.isNotEmpty ? review.photoUrls.first : null;

    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppConstants.spaceSm),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.borderSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Preview of the review being acted on.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spaceLg,
                AppConstants.spaceLg,
                AppConstants.spaceLg,
                AppConstants.spaceSm,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: cover != null
                          ? FadeInNetworkImage(url: cover, borderRadius: 8)
                          : Container(
                              color: c.bgSkeleton,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.restaurant,
                                size: 20,
                                color: c.textTertiary,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          review.placeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.star_rounded, size: 13, color: c.secondary),
                            const SizedBox(width: 2),
                            Text(
                              review.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 12,
                                color: c.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(review.createdAt),
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 12,
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: c.borderPrimary),
            _OptionRow(
              icon: Icons.edit_outlined,
              label: labels.editReview,
              color: c.textPrimary,
              onTap: () => Navigator.of(context).pop(ReviewAction.edit),
            ),
            _OptionRow(
              icon: Icons.delete_outline,
              label: labels.deleteReview,
              color: danger,
              onTap: () => Navigator.of(context).pop(ReviewAction.delete),
            ),
            Divider(height: 1, thickness: 0.5, color: c.borderPrimary),
            _OptionRow(
              icon: Icons.close_rounded,
              label: labels.cancel,
              color: c.textSecondary,
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: AppConstants.spaceSm),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SizedBox(width: AppConstants.spaceLg),
            Icon(icon, size: 24, color: color),
            const SizedBox(width: AppConstants.spaceMd),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
