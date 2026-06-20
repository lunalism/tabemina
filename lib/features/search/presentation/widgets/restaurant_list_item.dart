import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics_origin.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/network_image_fade.dart';
import '../../../home/data/datasources/places_api_datasource.dart';
import '../../../home/data/models/nearby_restaurant.dart';

/// One row in the Search bottom sheet — thumbnail, name, meta line, and a
/// tap target that opens the restaurant detail screen.
///
/// Distance is rendered when [userLat] / [userLng] are present; the meta
/// string degrades gracefully (skips segments rather than rendering "★ —")
/// when individual fields are missing.
class RestaurantListItem extends StatelessWidget {
  const RestaurantListItem({
    super.key,
    required this.restaurant,
    this.userLat,
    this.userLng,
  });

  final NearbyRestaurant restaurant;
  final double? userLat;
  final double? userLng;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: () => context.push(
        AppRoutes.restaurantDetailFor(restaurant.id),
        extra: AnalyticsOrigin.searchResult,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceLg,
          vertical: AppConstants.spaceSm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Thumbnail(photoName: restaurant.photoName),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _MetaLine(
                    restaurant: restaurant,
                    userLat: userLat,
                    userLng: userLng,
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

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.photoName});

  final String? photoName;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 48,
        height: 48,
        child: photoName != null
            ? FadeInNetworkImage(
                url: PlacesApiDatasource.photoUrl(photoName!, maxHeightPx: 200),
                headers: kPlacesPhotoHeaders,
                errorPlaceholder: _placeholder(c),
              )
            : _placeholder(c),
      ),
    );
  }

  Widget _placeholder(AppColors c) {
    return Container(
      color: c.bgSkeleton,
      alignment: Alignment.center,
      child: Icon(Icons.restaurant, size: 20, color: c.textTertiary),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.restaurant,
    required this.userLat,
    required this.userLng,
  });

  final NearbyRestaurant restaurant;
  final double? userLat;
  final double? userLng;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final parts = <String>[];
    if (restaurant.rating != null) {
      final count = restaurant.userRatingCount != null
          ? ' (${restaurant.userRatingCount})'
          : '';
      parts.add('★ ${restaurant.rating!.toStringAsFixed(1)}$count');
    }
    if (restaurant.priceLevel != null) {
      parts.add(restaurant.priceLevel!.display);
    }
    final distance = _formatDistance();
    if (distance != null) parts.add(distance);

    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join('  ·  '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 12,
        color: c.textSecondary,
      ),
    );
  }

  String? _formatDistance() {
    if (userLat == null || userLng == null) return null;
    final meters = Geolocator.distanceBetween(
      userLat!,
      userLng!,
      restaurant.latitude,
      restaurant.longitude,
    );
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
}
