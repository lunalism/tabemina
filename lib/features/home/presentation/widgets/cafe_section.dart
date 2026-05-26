import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/popular_restaurants_provider.dart';
import 'popular_card_skeleton.dart';
import 'popular_restaurant_card.dart';

/// "Cafes nearby" — same horizontal carousel as the popular section, but
/// driven by [nearbyCafesProvider] (cafes / bakeries / dessert shops).
///
/// Visually distinguished by a warm-brown coffee-cup icon on the header so
/// the cafe row reads differently from the coral-flame popular row.
class CafeSection extends ConsumerWidget {
  const CafeSection({super.key});

  static const double _carouselHeight = 192;

  // Header coffee-cup tint — warm brown to contrast against the coral primary
  // already used by the Popular section. One-off design accents; intentionally
  // not promoted into [AppColors].
  static const _coffeeBrownDark = Color(0xFFC4956A);
  static const _coffeeBrownLight = Color(0xFF8B6A47);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(nearbyCafesProvider);

    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(),
          const SizedBox(height: AppConstants.spaceSm),
          SizedBox(
            height: _carouselHeight,
            child: async.when(
              loading: () => const _LoadingRow(),
              error: (_, _) => _ErrorState(
                onRetry: () => ref.invalidate(nearbyCafesProvider),
              ),
              data: (items) => items.isEmpty
                  ? const _EmptyState()
                  : _Carousel(items: items),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? CafeSection._coffeeBrownDark
        : CafeSection._coffeeBrownLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        0,
        AppConstants.spaceLg,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.local_cafe_outlined, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Text(
            'Cafes nearby',
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
            'No cafes found nearby',
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
            "Couldn't load cafes",
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
