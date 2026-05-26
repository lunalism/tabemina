import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../home/data/models/nearby_restaurant.dart' show PriceLevel;
import '../../domain/models/bookmarked_restaurant.dart';
import '../providers/bookmarks_provider.dart';

/// One row in the Bookmarks list.
///
/// Tapping the row opens the Detail page; tapping the filled bookmark icon
/// triggers an inline confirm-then-remove flow.
class BookmarkCard extends StatelessWidget {
  const BookmarkCard({
    super.key,
    required this.bookmark,
    required this.labels,
    required this.onRemove,
  });

  final BookmarkedRestaurant bookmark;
  final BookmarksLabels labels;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: () => context.push(AppRoutes.restaurantDetailFor(bookmark.placeId)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: c.borderPrimary, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.all(AppConstants.spaceMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumbnail(photoUrl: bookmark.photoUrl),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bookmark.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                  if (bookmark.primaryType != null &&
                      bookmark.primaryType!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatType(bookmark.primaryType!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  _MetaLine(bookmark: bookmark),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.spaceSm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                InkResponse(
                  onTap: () => _confirmRemove(context),
                  radius: 20,
                  child: Icon(
                    Icons.bookmark_rounded,
                    size: 22,
                    color: c.primary,
                  ),
                ),
                const SizedBox(height: AppConstants.spaceXs),
                Text(
                  '${labels.savedPrefix} ${formatRelativeSaved(bookmark.savedAt, labels)}',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 11,
                    color: c.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _RemoveDialog(labels: labels),
    );
    if (ok == true) onRemove();
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
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 72,
        height: 72,
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(c),
              )
            : _placeholder(c),
      ),
    );
  }

  Widget _placeholder(AppColors c) {
    return Container(
      color: c.bgSkeleton,
      alignment: Alignment.center,
      child: Icon(Icons.restaurant, size: 28, color: c.textTertiary),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.bookmark});

  final BookmarkedRestaurant bookmark;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final parts = <String>[];
    if (bookmark.rating != null) {
      final count = bookmark.userRatingCount != null
          ? ' (${bookmark.userRatingCount})'
          : '';
      parts.add('★ ${bookmark.rating!.toStringAsFixed(1)}$count');
    }
    final price = PriceLevel.fromApi(bookmark.priceLevel)?.display;
    if (price != null) parts.add(price);

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
}

class _RemoveDialog extends StatelessWidget {
  const _RemoveDialog({required this.labels});

  final BookmarksLabels labels;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Dialog(
      backgroundColor: c.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              labels.removeConfirmTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.spaceSm),
            Text(
              labels.removeConfirmBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                color: c.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            InkWell(
              onTap: () => Navigator.of(context).pop(true),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 44,
                alignment: Alignment.center,
                child: Text(
                  labels.removeYes,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: c.errorText,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => Navigator.of(context).pop(false),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels.removeNo,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
