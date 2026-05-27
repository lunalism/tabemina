import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/shimmer_box.dart';

/// Skeleton card shown while popular / nearby-cafes load. Width matches
/// the live [PopularRestaurantCard] (150px) plus the same vertical
/// rhythm so the carousel doesn't jump on resolve.
class PopularCardSkeleton extends StatelessWidget {
  const PopularCardSkeleton({super.key, this.opacity = 1.0});

  /// Lets the parent list fade trailing cards (e.g. 1.0 / 0.5 / 0.2)
  /// to suggest "more content loading just out of view".
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: c.bgCard,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(color: c.borderPrimary, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ShimmerBox(width: 150, height: 110),
            Padding(
              padding: EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 110, height: 12),
                  SizedBox(height: 6),
                  ShimmerBox(width: 80, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
