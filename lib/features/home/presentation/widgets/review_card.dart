import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Mock review entry — avatar, photos, blurb, and restaurant link.
@immutable
class ReviewCardData {
  const ReviewCardData({
    required this.initials,
    required this.username,
    required this.timeAgo,
    required this.photoCount,
    required this.text,
    required this.restaurantName,
    required this.rating,
  });

  final String initials;
  final String username;
  final String timeAgo;
  final int photoCount;
  final String text;
  final String restaurantName;
  final double rating;
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.data});

  final ReviewCardData data;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // Stack lets the coral bar stretch to the card's natural height without
    // pulling [IntrinsicHeight] into the layout (which blew up to infinite
    // height under the Column-in-SingleChildScrollView parent and hid the
    // 2nd and 3rd cards in the first pass of this design).
    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderPrimary, width: 0.5),
      ),
      child: Stack(
        children: [
          // Card body — left padding leaves room for the bar (3px) plus an
          // 8px breathing gap before the avatar / text starts.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spaceMd + 11,
              AppConstants.spaceMd,
              AppConstants.spaceMd,
              AppConstants.spaceMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(data: data),
                const SizedBox(height: AppConstants.spaceSm),
                _Photos(count: data.photoCount),
                const SizedBox(height: AppConstants.spaceSm),
                Text(
                  '"${data.text}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    color: c.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppConstants.spaceSm),
                _RestaurantLink(
                  name: data.restaurantName,
                  rating: data.rating,
                ),
              ],
            ),
          ),
          // Coral accent bar — pinned to the left edge, 8px inset top/bottom
          // so it reads as a brand mark rather than a hard divider.
          Positioned(
            left: AppConstants.spaceMd,
            top: 8,
            bottom: 8,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.data});

  final ReviewCardData data;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: c.bgSkeleton,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            data.initials,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spaceSm),
        Text(
          data.username,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: c.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          data.timeAgo,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 10,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Photos extends StatelessWidget {
  const _Photos({required this.count});

  final int count;

  // Placeholder gradients — kept local because they're only used for the
  // empty-photo state on mock reviews and don't belong in the global palette.
  static const _gradientLight = [Color(0xFFF5F3EE), Color(0xFFEBE9E2)];
  static const _gradientDark = [Color(0xFF2A2924), Color(0xFF333330)];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? _gradientDark : _gradientLight;

    return Row(
      children: List.generate(count, (i) {
        return Padding(
          padding: EdgeInsets.only(right: i == count - 1 ? 0 : 8),
          child: Container(
            width: 90,
            height: 68,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.borderPrimary, width: 0.5),
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: 0.3,
              child: Icon(
                Icons.restaurant,
                size: 24,
                color: c.textSecondary,
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _RestaurantLink extends StatelessWidget {
  const _RestaurantLink({required this.name, required this.rating});

  final String name;
  final double rating;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Icon(Icons.place_outlined, size: 12, color: c.primary),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 11,
              color: c.primary,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.star_rounded, size: 11, color: c.textSecondary),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 11,
            color: c.textSecondary,
          ),
        ),
      ],
    );
  }
}
