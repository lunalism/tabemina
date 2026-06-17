import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics_origin.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/network_image_fade.dart';
import '../../data/datasources/places_api_datasource.dart';
import '../../data/models/nearby_restaurant.dart';

/// One card in the "Popular near you" carousel.
///
/// Width is fixed (150px) so the parent [ListView] can scroll smoothly without
/// per-item layout math. Photo is loaded directly through the Places photo
/// endpoint, which 302-redirects to googleusercontent — `Image.network`
/// follows that.
class PopularRestaurantCard extends StatelessWidget {
  const PopularRestaurantCard({
    super.key,
    required this.rank,
    required this.restaurant,
  });

  final int rank;
  final NearbyRestaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // Soft warm lift so the card separates from the off-white page background
    // (light only — cardShadow is transparent in dark). The shadow sits on a
    // wrapper because the Material below clips its children (antiAlias).
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        boxShadow: [
          BoxShadow(
            color: c.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: c.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(
            AppRoutes.restaurantDetailFor(restaurant.id),
            extra: AnalyticsOrigin.homeFeed,
          ),
          child: Container(
            width: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              border: Border.all(color: c.borderPrimary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    _Photo(photoName: restaurant.photoName),
                    Positioned(top: 6, left: 6, child: _RankBadge(rank: rank)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _MetaLine(restaurant: restaurant),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.photoName});

  final String? photoName;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (photoName == null) return _placeholder(c);
    return FadeInNetworkImage(
      url: PlacesApiDatasource.photoUrl(photoName!),
      width: 150,
      height: 110,
      errorPlaceholder: _placeholder(c),
    );
  }

  Widget _placeholder(AppColors c) {
    return Container(
      width: 150,
      height: 110,
      color: c.bgSkeleton,
      alignment: Alignment.center,
      child: Icon(Icons.photo_camera_outlined, size: 28, color: c.textTertiary),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.onPrimary,
          height: 1.0,
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.restaurant});

  final NearbyRestaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ratingText = restaurant.rating != null
        ? restaurant.rating!.toStringAsFixed(1)
        : '—';
    final countText = restaurant.userRatingCount != null
        ? ' (${restaurant.userRatingCount})'
        : '';
    final priceText = restaurant.priceLevel != null
        ? '  |  ${restaurant.priceLevel!.display}'
        : '';

    return DefaultTextStyle.merge(
      style: TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 11,
        color: c.textSecondary,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.star_rounded, size: 12, color: c.secondary),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              '$ratingText$countText$priceText',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
