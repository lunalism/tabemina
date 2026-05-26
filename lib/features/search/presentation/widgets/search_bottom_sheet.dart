import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/providers/location_providers.dart';
import '../providers/search_providers.dart';
import 'filter_chip_row.dart';
import 'restaurant_list_item.dart';
import 'search_empty_state.dart';

/// Bottom sheet for the Search tab — 3-snap draggable list, driven by
/// [searchResultsProvider].
///
/// Snap states (fractions of the host's available height):
///   - collapsed (0.20): handle + header + a single peek card visible
///   - half      (0.52): + filter chips + a few cards visible
///   - full      (0.86): full list scrolls inside the sheet
class SearchBottomSheet extends ConsumerWidget {
  const SearchBottomSheet({super.key, required this.controller});

  final DraggableScrollableController controller;

  /// Snap fractions of the parent height.
  static const double collapsedSize = 0.20;
  static const double halfSize = 0.52;
  static const double fullSize = 0.86;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The handle uses different border tokens per mode to match the spec
    // (#D3D1C7 light / #444441 dark) without introducing a one-off token.
    final handleColor = isDark ? c.borderPrimary : c.borderSecondary;

    final lang = ref.watch(appLocaleProvider).languageCode;
    final labels = SearchHeaderLabels.of(lang);
    final asyncResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final hasQuery = query.isNotEmpty;
    final userPosition = ref
        .watch(currentPositionProvider)
        .maybeWhen(data: (p) => p, orElse: () => null);

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
                _SheetHeader(
                  hasQuery: hasQuery,
                  count: asyncResults.maybeWhen(
                    data: (list) => list.length,
                    orElse: () => 0,
                  ),
                  labels: labels,
                ),
                const SizedBox(height: AppConstants.spaceSm),
                const FilterChipRow(),
                const SizedBox(height: AppConstants.spaceXs),
                ...asyncResults.when(
                  loading: () => [const _LoadingRow()],
                  error: (e, _) => [_ErrorRow(message: e.toString())],
                  data: (items) {
                    if (items.isEmpty) {
                      if (hasQuery) {
                        return [SearchEmptyState(labels: labels)];
                      }
                      return [const _NearbyEmptyRow()];
                    }
                    return [
                      for (final r in items)
                        RestaurantListItem(
                          restaurant: r,
                          userLat: userPosition?.latitude,
                          userLng: userPosition?.longitude,
                        ),
                    ];
                  },
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
  const _SheetHeader({
    required this.hasQuery,
    required this.count,
    required this.labels,
  });

  final bool hasQuery;
  final int count;
  final SearchHeaderLabels labels;

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
            hasQuery ? labels.results : labels.nearYou,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(width: AppConstants.spaceSm),
          Text(
            labels.found(count),
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              color: c.textSecondary,
            ),
          ),
          const Spacer(),
          if (!hasQuery)
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(AppConstants.radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceXs,
                  vertical: 2,
                ),
                child: Text(
                  labels.filter,
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

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceLg),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceLg,
        vertical: AppConstants.spaceLg,
      ),
      child: Text(
        message,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12,
          color: c.errorText,
        ),
      ),
    );
  }
}

class _NearbyEmptyRow extends StatelessWidget {
  const _NearbyEmptyRow();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceLg,
        vertical: AppConstants.spaceLg,
      ),
      child: Text(
        'No restaurants nearby',
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          color: c.textSecondary,
        ),
      ),
    );
  }
}
