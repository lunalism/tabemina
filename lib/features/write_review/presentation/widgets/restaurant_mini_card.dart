import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/network_image_fade.dart';
import '../../domain/models/review_draft.dart';

/// Compact row showing the restaurant a review is being written for.
///
/// Shown once a restaurant is selected (either via the Detail-screen entry
/// point or via the in-screen search). "Change" hands control back to the
/// search view.
class RestaurantMiniCard extends StatelessWidget {
  const RestaurantMiniCard({
    super.key,
    required this.restaurant,
    required this.onChange,
    required this.changeLabel,
  });

  final ReviewRestaurant restaurant;
  final VoidCallback? onChange;
  final String changeLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.bgCard,
        border: Border(
          bottom: BorderSide(color: c.borderPrimary, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceLg,
        vertical: AppConstants.spaceMd,
      ),
      child: Row(
        children: [
          _Thumbnail(photoUrl: restaurant.photoUrl),
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
                if (restaurant.primaryType != null &&
                    restaurant.primaryType!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatType(restaurant.primaryType!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onChange != null)
            TextButton(
              onPressed: onChange,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceSm,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                changeLabel,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatType(String raw) {
    final words = raw.split('_');
    if (words.isEmpty) return '';
    final first = words.first;
    final capitalized = first.isEmpty
        ? ''
        : '${first[0].toUpperCase()}${first.substring(1)}';
    return [capitalized, ...words.skip(1)].join(' ');
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 44,
        height: 44,
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? FadeInNetworkImage(
                url: photoUrl!,
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
