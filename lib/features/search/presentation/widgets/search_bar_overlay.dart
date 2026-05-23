import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Floating, pill-shaped search bar drawn over the map.
///
/// Visual-only for now — taps are accepted (so the splash ripple feels
/// responsive) but no navigation is wired up; that comes in the Search tab
/// integration.
class SearchBarOverlay extends StatelessWidget {
  const SearchBarOverlay({
    super.key,
    this.placeholder = 'Search restaurants, areas...',
    this.locationLabel = 'Tokyo',
    this.onTap,
  });

  final String placeholder;
  final String locationLabel;
  final VoidCallback? onTap;

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final topInset = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        topInset + AppConstants.spaceSm,
        AppConstants.spaceLg,
        0,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusXl),
          child: Container(
            height: _height,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceLg,
            ),
            decoration: BoxDecoration(
              color: c.bgCard,
              borderRadius: BorderRadius.circular(AppConstants.radiusXl),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 12,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: c.textSecondary),
                const SizedBox(width: AppConstants.spaceSm),
                Expanded(
                  child: Text(
                    placeholder,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      color: c.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppConstants.spaceSm),
                _LocationBadge(label: locationLabel, color: c.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationBadge extends StatelessWidget {
  const _LocationBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.place_outlined, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
