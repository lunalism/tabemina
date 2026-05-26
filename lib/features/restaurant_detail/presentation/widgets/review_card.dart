import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Mock-only review row for the detail screen. Real review data plugs in
/// during Part 2.
@immutable
class DetailReviewData {
  const DetailReviewData({
    required this.initials,
    required this.avatarColor,
    required this.name,
    required this.date,
    required this.rating,
    required this.comment,
    required this.photoCount,
  });

  final String initials;
  final Color avatarColor;
  final String name;
  final String date;
  final double rating;
  final String comment;
  final int photoCount;
}

class DetailReviewCard extends StatelessWidget {
  const DetailReviewCard({super.key, required this.data});

  final DetailReviewData data;

  // Photo placeholder gradients — match the home review card so the two
  // surfaces feel like the same product.
  static const _gradientLight = [Color(0xFFF5F3EE), Color(0xFFEBE9E2)];
  static const _gradientDark = [Color(0xFF2A2924), Color(0xFF333330)];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? _gradientDark : _gradientLight;

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
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: data.avatarColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  data.initials,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spaceSm),
              Expanded(
                child: Text(
                  data.name,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
              ),
              Text(
                data.date,
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
                data.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Text(
            data.comment,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              color: c.textPrimary,
              height: 1.4,
            ),
          ),
          if (data.photoCount > 0) ...[
            const SizedBox(height: AppConstants.spaceSm),
            Row(
              children: [
                for (int i = 0; i < data.photoCount; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      right: i == data.photoCount - 1 ? 0 : 8,
                    ),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradient,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: c.borderPrimary, width: 0.5),
                      ),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: 0.3,
                        child: Icon(
                          Icons.restaurant,
                          size: 20,
                          color: c.textSecondary,
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
