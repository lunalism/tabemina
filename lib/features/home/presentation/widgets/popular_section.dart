import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/popular_restaurants_provider.dart';
import 'popular_card_skeleton.dart';
import 'popular_restaurant_card.dart';

/// "Popular near you" — section header + horizontal carousel.
///
/// All three async states (loading / data+empty / error) render at the same
/// height so the surrounding feed doesn't jump when the request resolves.
class PopularSection extends ConsumerWidget {
  const PopularSection({super.key});

  static const double _carouselHeight = 192;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(popularRestaurantsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(),
        const SizedBox(height: AppConstants.spaceSm),
        SizedBox(
          height: _carouselHeight,
          child: async.when(
            loading: () => const _LoadingRow(),
            error: (_, _) => _ErrorState(
              onRetry: () => ref.invalidate(popularRestaurantsProvider),
            ),
            data: (items) => items.isEmpty
                ? const _EmptyState()
                : _Carousel(items: items),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 18,
            color: c.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'Popular near you',
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

class _Carousel extends StatelessWidget {
  const _Carousel({required this.items});

  final List items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, i) {
        return PopularRestaurantCard(rank: i + 1, restaurant: items[i]);
      },
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, _) => const PopularCardSkeleton(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_outlined, size: 32, color: c.textTertiary),
          const SizedBox(height: AppConstants.spaceSm),
          Text(
            'No restaurants found nearby',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Couldn't load restaurants",
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spaceSm),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: c.primary,
              side: BorderSide(color: c.primary),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
