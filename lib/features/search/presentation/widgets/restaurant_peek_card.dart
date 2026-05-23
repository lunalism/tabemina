import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// One row in the bottom sheet's restaurant list — small thumbnail,
/// name, and a single-line meta string.
class RestaurantPeekCard extends StatelessWidget {
  const RestaurantPeekCard({
    super.key,
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.priceRange,
    required this.priceEstimate,
    required this.distance,
  });

  final String name;
  final double rating;
  final int reviewCount;
  final String priceRange;
  final String priceEstimate;
  final String distance;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final meta =
        '★ ${rating.toStringAsFixed(1)} ($reviewCount)  |  $priceRange $priceEstimate  |  $distance';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceLg,
        vertical: AppConstants.spaceSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.bgSkeleton,
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            ),
            child: Icon(
              Icons.restaurant,
              size: 18,
              color: c.textTertiary,
            ),
          ),
          const SizedBox(width: AppConstants.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 11,
                    color: c.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
