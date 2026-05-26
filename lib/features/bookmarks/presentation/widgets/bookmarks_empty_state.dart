import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../bookmarks_labels.dart';

/// Shown when [bookmarksProvider] resolves to an empty list. The "Explore
/// nearby" CTA hops the user back to the Home tab where they can find
/// places to save.
class BookmarksEmptyState extends StatelessWidget {
  const BookmarksEmptyState({super.key, required this.labels});

  final BookmarksLabels labels;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_outline_rounded,
              size: 48,
              color: c.textSecondary,
            ),
            const SizedBox(height: AppConstants.spaceMd),
            Text(
              labels.empty,
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
              labels.emptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                color: c.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.home),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.primary,
                side: BorderSide(color: c.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusFull),
                ),
              ),
              child: Text(
                labels.exploreNearby,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
