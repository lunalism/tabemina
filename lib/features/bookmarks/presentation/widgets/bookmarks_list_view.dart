import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_origin.dart';
import '../../../../core/providers/analytics_providers.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../presentation/providers/bookmark_providers.dart';
import '../../../../shared/widgets/tab_scaffold.dart';
import '../../../../shared/widgets/app_error_kind.dart';
import '../../../../shared/widgets/app_state_labels.dart';
import '../../../../shared/widgets/restaurant_row_skeleton.dart';
import '../bookmarks_labels.dart';
import 'bookmark_card.dart';
import 'bookmarks_empty_state.dart';

/// The body of the bookmarks list — loading skeleton / error / empty / list
/// — without any screen chrome. Shared by the Bookmarks tab and the My Page
/// "Saved" tab so the two never drift.
///
/// [shrinkWrap] = true makes the list size to its content and disables its
/// own scrolling, for embedding inside an outer scroll view (My Page). When
/// false it scrolls on its own and expects to be given bounded height
/// (e.g. inside an [Expanded]).
class BookmarksListView extends ConsumerWidget {
  const BookmarksListView({super.key, this.shrinkWrap = false});

  final bool shrinkWrap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBookmarks = ref.watch(bookmarksProvider);
    final lang = ref.watch(appLocaleProvider).languageCode;
    final labels = BookmarksLabels.of(lang);
    final stateLabels = AppStateLabels.of(lang);

    return asyncBookmarks.when(
      loading: () => const _Loading(),
      error: (e, _) => _Centered(
        shrinkWrap: shrinkWrap,
        child: errorStateView(
          context,
          error: e,
          labels: stateLabels,
          onRetry: () => ref.invalidate(bookmarksProvider),
        ),
      ),
      data: (bookmarks) {
        if (bookmarks.isEmpty) {
          return const _Centered(
            shrinkWrap: true,
            child: BookmarksEmptyState(),
          );
        }
        return ListView.builder(
          // When standalone (Bookmarks tab) clear the floating nav; when
          // embedded in My Page (shrinkWrap) the host scroll handles it.
          padding: shrinkWrap
              ? EdgeInsets.zero
              : EdgeInsets.only(bottom: floatingNavContentInset(context)),
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
          itemCount: bookmarks.length,
          itemBuilder: (_, i) => BookmarkCard(
            bookmark: bookmarks[i],
            labels: labels,
            onRemove: () async {
              final placeId = bookmarks[i].placeId;
              await ref.read(bookmarkRepositoryProvider).removeBookmark(placeId);
              // Surface-where-the-action-happened: the saved (bookmarks) list.
              ref.read(analyticsEventsProvider).bookmarkRemoved(
                    restaurantId: placeId,
                    origin: AnalyticsOrigin.bookmarkList,
                  );
            },
          ),
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: RestaurantRowSkeletonList(),
    );
  }
}

/// Centers a child; when embedded (shrinkWrap) it needs a min height so the
/// empty/error state doesn't collapse to zero inside an outer scroll view.
class _Centered extends StatelessWidget {
  const _Centered({required this.child, required this.shrinkWrap});

  final Widget child;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    if (shrinkWrap) {
      return SizedBox(
        height: 320,
        child: Center(child: child),
      );
    }
    return Center(child: child);
  }
}
