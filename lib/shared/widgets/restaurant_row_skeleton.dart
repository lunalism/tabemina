import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import 'shimmer_box.dart';

/// Skeleton for a list/sheet row that resolves to a restaurant tile —
/// thumbnail on the left, name + meta + a couple of tag pills on the
/// right. Used by the Search bottom sheet, the Bookmarks tab, and the
/// in-screen search step on the Write Review flow so the loading
/// affordance reads the same across all three surfaces.
class RestaurantRowSkeleton extends StatelessWidget {
  const RestaurantRowSkeleton({super.key, this.opacity = 1.0});

  /// Lets the parent list fade trailing rows (1.0 / 0.5 / 0.2) so the
  /// last row reads as "more loading just out of view".
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceLg,
          vertical: AppConstants.spaceSm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            ShimmerBox(width: 64, height: 64, borderRadius: 8),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShimmerBox(width: 140, height: 12),
                  SizedBox(height: 6),
                  ShimmerBox(width: 100, height: 10),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      ShimmerBox(width: 42, height: 16, borderRadius: 12),
                      SizedBox(width: 6),
                      ShimmerBox(width: 42, height: 16, borderRadius: 12),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vertical stack of [RestaurantRowSkeleton]s with the standard 100/50/20
/// fade-out tail. Default count is 3 to match the typical "few items at
/// a glance" affordance.
class RestaurantRowSkeletonList extends StatelessWidget {
  const RestaurantRowSkeletonList({super.key, this.count = 3});

  final int count;

  static const _fades = [1.0, 0.5, 0.2];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < count; i++)
          RestaurantRowSkeleton(
            opacity: i < _fades.length ? _fades[i] : _fades.last,
          ),
      ],
    );
  }
}
