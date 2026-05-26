import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/search_providers.dart';

/// Shown inside the bottom sheet when a text search returns zero hits.
///
/// "Clear search" wipes [searchQueryProvider] so the screen falls back to
/// the nearby state without the user having to manually empty the field.
class SearchEmptyState extends ConsumerWidget {
  const SearchEmptyState({super.key, required this.labels});

  final SearchHeaderLabels labels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceLg,
        vertical: AppConstants.space2xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 40, color: c.textTertiary),
          const SizedBox(height: AppConstants.spaceSm),
          Text(
            labels.noResults,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            labels.tryDifferent,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 12,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spaceMd),
          OutlinedButton(
            onPressed: () =>
                ref.read(searchQueryProvider.notifier).clear(),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.primary,
              side: BorderSide(color: c.primary),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              ),
            ),
            child: Text(
              labels.clearSearch,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
