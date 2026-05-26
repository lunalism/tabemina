import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/place_detail.dart';

/// Name + category line + rating + open-status chip + editorial blurb.
class InfoSection extends StatelessWidget {
  const InfoSection({super.key, required this.detail});

  final PlaceDetail detail;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categoryLine = _buildCategoryLine();
    final openNow = detail.currentOpeningHours?.openNow;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.displayName,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          if (categoryLine != null) ...[
            const SizedBox(height: 4),
            Text(
              categoryLine,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                color: c.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppConstants.spaceSm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (detail.rating != null) ...[
                Icon(Icons.star_rounded, size: 16, color: c.secondary),
                const SizedBox(width: 4),
                Text(
                  detail.rating!.toStringAsFixed(1),
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                if (detail.userRatingCount != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${detail.userRatingCount} reviews)',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      color: c.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(width: AppConstants.spaceSm),
              ],
              if (openNow != null) _StatusChip(open: openNow, isDark: isDark),
            ],
          ),
          if (detail.editorialSummary != null &&
              detail.editorialSummary!.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spaceSm),
            Text(
              detail.editorialSummary!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: c.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _buildCategoryLine() {
    final category = detail.primaryType == null || detail.primaryType!.isEmpty
        ? null
        : formatPrimaryType(detail.primaryType!);
    final price = formatYenPriceLevel(detail.priceLevel);
    if (category == null && price == null) return null;
    if (category != null && price != null) return '$category · $price';
    return category ?? price;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.open, required this.isDark});

  final bool open;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = open ? const Color(0xFF1A9E75) : const Color(0xFFC4453E);
    // Tinted backgrounds: light mode uses a 14% alpha pastel, dark uses a 24%
    // alpha so the chip stays legible against the warm dark surface.
    final bg = color.withValues(alpha: isDark ? 0.24 : 0.14);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            open ? Icons.check_circle_rounded : Icons.access_time_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            open ? 'Open now' : 'Closed',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
