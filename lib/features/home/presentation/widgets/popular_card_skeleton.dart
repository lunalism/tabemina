import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Pulsing placeholder card shown while popular restaurants load.
///
/// Rolled by hand (a single repeating [AnimationController] driving opacity)
/// so we don't pull in the `shimmer` package for one screen.
class PopularCardSkeleton extends StatefulWidget {
  const PopularCardSkeleton({super.key});

  @override
  State<PopularCardSkeleton> createState() => _PopularCardSkeletonState();
}

class _PopularCardSkeletonState extends State<PopularCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final opacity = 0.45 + 0.55 * t;
        return Opacity(
          opacity: opacity,
          child: Container(
            width: 150,
            decoration: BoxDecoration(
              color: c.bgCard,
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150,
                  height: 110,
                  decoration: BoxDecoration(
                    color: c.bgSkeleton,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppConstants.radiusMd),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: 110,
                        decoration: BoxDecoration(
                          color: c.bgSkeleton,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 80,
                        decoration: BoxDecoration(
                          color: c.bgSkeleton,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
