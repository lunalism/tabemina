import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../mypage_labels.dart';

/// Empty state for the "My reviews" tab — camera-in-coral-circle, prompt,
/// and a full-width "Write first review" CTA.
class ReviewsEmptyState extends StatelessWidget {
  const ReviewsEmptyState({
    super.key,
    required this.labels,
    required this.onWriteReview,
  });

  final MyPageLabels labels;
  final VoidCallback onWriteReview;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.photo_camera_outlined, size: 40, color: c.primary),
          ),
          const SizedBox(height: 12),
          Text(
            labels.noReviewsYet,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            labels.noReviewsDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              color: c.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: onWriteReview,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels.writeFirstReview,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
