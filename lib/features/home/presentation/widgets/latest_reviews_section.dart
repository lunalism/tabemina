import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import 'review_card.dart';

/// "Latest reviews" — vertical stack of 3 mock review cards.
class LatestReviewsSection extends StatelessWidget {
  const LatestReviewsSection({super.key});

  static const _reviews = <ReviewCardData>[
    ReviewCardData(
      initials: 'YK',
      username: 'yuki_eats',
      timeAgo: '2h ago',
      photoCount: 2,
      text:
          'The tonkotsu broth was incredibly rich. Best ramen I\'ve had in Shibuya!',
      restaurantName: 'Ichiran Shibuya',
      rating: 5.0,
    ),
    ReviewCardData(
      initials: 'TM',
      username: 'tokyo_mike',
      timeAgo: '5h ago',
      photoCount: 1,
      text: 'Omakase course was worth every yen. The uni was unreal.',
      restaurantName: 'Sushi Saito Annex',
      rating: 4.5,
    ),
    ReviewCardData(
      initials: 'SK',
      username: 'seoul_kim',
      timeAgo: '1d ago',
      photoCount: 2,
      text:
          'Finally found good Korean BBQ in Tokyo! The galbi was perfectly marinated.',
      restaurantName: 'Kang Hodong Baekjeong',
      rating: 4.3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.space2xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(),
          const SizedBox(height: AppConstants.spaceSm),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceLg,
            ),
            child: Column(
              children: [
                for (int i = 0; i < _reviews.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  ReviewCard(data: _reviews[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 18, color: c.secondary),
          const SizedBox(width: 6),
          Text(
            'Latest reviews',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceXs,
                vertical: 2,
              ),
              child: Text(
                'See all >',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
