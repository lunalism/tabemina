import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/providers/connectivity_providers.dart';
import '../../../../core/providers/location_providers.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/utils/keyboard.dart';
import '../../../../shared/widgets/app_error_kind.dart';
import '../../../../shared/widgets/app_state_labels.dart';
import '../../../../shared/widgets/nav_compact_scroller.dart';
import '../../../../shared/widgets/restaurant_row_skeleton.dart';
import '../../../../shared/widgets/tab_scaffold.dart';
import '../providers/search_providers.dart';
import 'filter_chip_row.dart';
import 'restaurant_list_item.dart';
import 'search_empty_state.dart';
import 'search_offline_state.dart';

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
    final isOffline =
        ref.watch(connectivityStatusProvider).asData?.value ==
        NetworkStatus.offline;
    final query = ref.watch(searchQueryProvider);
    final hasQuery = query.isNotEmpty;
    final userPosition = ref
        .watch(currentPositionProvider)
        .maybeWhen(data: (p) => p, orElse: () => null);

    // Below full expansion the sheet consumes drags as EXTENT changes — the
    // inner list's scroll position never moves, so its onDrag
    // keyboardDismissBehavior never fires. Extent notifications cover that
    // case.
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        // Raw view insets (not MediaQuery — no rebuild dependency): only act
        // when the keyboard is actually up. Without this, focus isn't a
        // reliable proxy — the GoogleMap UiKitView requests LEAF focus on
        // native touches (platform_view.dart onFocus), so after any map pan
        // the first extent frame of every sheet drag would run a real
        // unfocus + platform-view Focus rebuild mid-gesture (visible jitter).
        if (View.of(context).viewInsets.bottom > 0) {
          dismissKeyboard();
        }
        return false; // Keep bubbling — don't swallow the notification.
      },
      child: DraggableScrollableSheet(
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
              child: NavCompactScroller(
                child: ListView(
                  controller: scrollController,
                  // Dragging the results list is a natural "done typing" signal.
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  // Clear the floating nav so the last result is reachable.
                  padding: EdgeInsets.only(
                    bottom: floatingNavContentInset(context),
                  ),
                  children: [
                    _DragHandle(color: handleColor),
                    _SheetHeader(
                      hasQuery: hasQuery,
                      count: asyncResults.maybeWhen(
                        data: (list) => list.length,
                        orElse: () => 0,
                      ),
                      // Offline shows "0 found" which reads as "nothing here"; hide
                      // the count and let the offline state below explain.
                      showCount: !isOffline,
                      labels: labels,
                    ),
                    const SizedBox(height: AppConstants.spaceSm),
                    const FilterChipRow(),
                    const SizedBox(height: AppConstants.spaceXs),
                    // Offline: a passive offline state stands in for the results —
                    // no Places query runs (the provider short-circuits too).
                    if (isOffline)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppConstants.spaceLg,
                        ),
                        child: SearchOfflineState(),
                      )
                    else
                      ...asyncResults.when(
                        loading: () => [const _LoadingRow()],
                        error: (e, _) => [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.spaceLg,
                            ),
                            child: errorStateView(
                              context,
                              error: e,
                              labels: AppStateLabels.of(lang),
                              onRetry: () =>
                                  ref.invalidate(searchResultsProvider),
                              compact: true,
                            ),
                          ),
                        ],
                        data: (items) {
                          if (items.isEmpty) {
                            if (hasQuery) {
                              return [const SearchEmptyState()];
                            }
                            // Empty nearby result is ambiguous: no GPS fix vs
                            // genuinely nothing around — say which one it was.
                            final noFix = ref.watch(
                              searchLocationUnavailableProvider,
                            );
                            return [
                              _NearbyEmptyRow(
                                message: noFix
                                    ? labels.locationUnavailable
                                    : labels.noNearby,
                              ),
                            ];
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
    required this.showCount,
    required this.labels,
  });

  final bool hasQuery;
  final int count;
  final bool showCount;
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
          if (showCount) ...[
            const SizedBox(width: AppConstants.spaceSm),
            Text(
              labels.found(count),
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                color: c.textSecondary,
              ),
            ),
          ],
          // The dead "Filter" text button that used to sit here was removed
          // (v1.1 deferral, same rationale as the See-all removals) — the
          // chip row right below already exposes filtering.
        ],
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return const RestaurantRowSkeletonList();
  }
}

class _NearbyEmptyRow extends StatelessWidget {
  const _NearbyEmptyRow({required this.message});

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
          fontSize: 13,
          color: c.textSecondary,
        ),
      ),
    );
  }
}
