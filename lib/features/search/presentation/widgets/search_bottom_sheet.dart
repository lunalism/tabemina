import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import 'filter_chip_row.dart';
import 'restaurant_peek_card.dart';

/// Bottom sheet for the Search tab — 3-snap draggable list of nearby restaurants.
///
/// Snap states (fractions of the host's available height):
///   - collapsed (0.20): handle + header + a single peek card visible
///   - half      (0.52): + filter chips + a few cards visible
///   - full      (0.86): full list scrolls inside the sheet
///
/// The sheet uses Flutter's [DraggableScrollableSheet] with `snap: true`, so
/// the same gesture that drags the sheet also scrolls the inner list once the
/// sheet has reached `maxChildSize`. Caller passes in a
/// [DraggableScrollableController] so it can drive both the sheet and other
/// chrome (e.g. the GPS button) that needs to track the sheet position.
class SearchBottomSheet extends StatelessWidget {
  const SearchBottomSheet({super.key, required this.controller});

  final DraggableScrollableController controller;

  /// Snap fractions of the parent height.
  static const double collapsedSize = 0.20;
  static const double halfSize = 0.52;
  static const double fullSize = 0.86;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The handle uses different border tokens per mode to match the spec
    // (#D3D1C7 light / #444441 dark) without introducing a one-off token.
    final handleColor = isDark ? c.borderPrimary : c.borderSecondary;

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: collapsedSize,
      minChildSize: collapsedSize,
      maxChildSize: fullSize,
      snap: true,
      snapSizes: const [collapsedSize, halfSize, fullSize],
      snapAnimationDuration: const Duration(milliseconds: 220),
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: c.bgCard,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusLg),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.radiusLg),
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              children: [
                _DragHandle(color: handleColor),
                const _SheetHeader(),
                const SizedBox(height: AppConstants.spaceSm),
                const FilterChipRow(),
                const SizedBox(height: AppConstants.spaceXs),
                for (final r in _mockRestaurants)
                  RestaurantPeekCard(
                    name: r.name,
                    rating: r.rating,
                    reviewCount: r.reviewCount,
                    priceRange: r.priceRange,
                    priceEstimate: r.priceEstimate,
                    distance: r.distance,
                  ),
                const SizedBox(height: AppConstants.space2xl),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spaceSm),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceMd,
        AppConstants.spaceLg,
        AppConstants.spaceSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'Near you',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(width: AppConstants.spaceSm),
          Text(
            '${_mockRestaurants.length} found',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              color: c.textSecondary,
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
                'Filter',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
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

typedef _MockRestaurant = ({
  String name,
  double rating,
  int reviewCount,
  String priceRange,
  String priceEstimate,
  String distance,
});

const List<_MockRestaurant> _mockRestaurants = [
  (
    name: 'Sample Restaurant',
    rating: 4.5,
    reviewCount: 89,
    priceRange: r'$$',
    priceEstimate: '~¥2,500',
    distance: '350m',
  ),
  (
    name: 'Ichiran Shibuya',
    rating: 4.3,
    reviewCount: 1240,
    priceRange: r'$$',
    priceEstimate: '~¥1,800',
    distance: '420m',
  ),
  (
    name: 'Sushi Saito Annex',
    rating: 4.8,
    reviewCount: 312,
    priceRange: r'$$$$',
    priceEstimate: '~¥18,000',
    distance: '680m',
  ),
  (
    name: 'Torikizoku Marunouchi',
    rating: 4.0,
    reviewCount: 542,
    priceRange: r'$',
    priceEstimate: '~¥1,200',
    distance: '510m',
  ),
  (
    name: 'Blue Bottle Aoyama',
    rating: 4.4,
    reviewCount: 803,
    priceRange: r'$$',
    priceEstimate: '~¥900',
    distance: '720m',
  ),
  (
    name: 'Gonpachi Nishi-Azabu',
    rating: 4.2,
    reviewCount: 967,
    priceRange: r'$$$',
    priceEstimate: '~¥6,500',
    distance: '1.1km',
  ),
  (
    name: 'Café Kitsuné Aoyama',
    rating: 4.5,
    reviewCount: 421,
    priceRange: r'$$',
    priceEstimate: '~¥1,400',
    distance: '850m',
  ),
];
