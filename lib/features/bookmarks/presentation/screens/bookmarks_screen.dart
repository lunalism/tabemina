import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../providers/bookmarks_provider.dart';
import '../widgets/bookmark_card.dart';
import '../widgets/bookmarks_empty_state.dart';

/// Bookmarks tab — header + count, then either the empty state or a vertical
/// list of saved restaurants.
///
/// The list is sorted newest-first by the notifier, so the screen just hands
/// each entry to a [BookmarkCard] in order.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final bookmarks = ref.watch(bookmarksProvider);
    final lang = ref.watch(appLocaleProvider).languageCode;
    final labels = BookmarksLabels.of(lang);

    return Scaffold(
      backgroundColor: c.bgPage,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(count: bookmarks.length, labels: labels),
            Expanded(
              child: bookmarks.isEmpty
                  ? BookmarksEmptyState(labels: labels)
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: bookmarks.length,
                      itemBuilder: (_, i) => BookmarkCard(
                        bookmark: bookmarks[i],
                        labels: labels,
                        onRemove: () => ref
                            .read(bookmarksProvider.notifier)
                            .remove(bookmarks[i].placeId),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.labels});

  final int count;
  final BookmarksLabels labels;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        AppConstants.spaceMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            labels.title,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: c.bgSkeleton,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: c.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
