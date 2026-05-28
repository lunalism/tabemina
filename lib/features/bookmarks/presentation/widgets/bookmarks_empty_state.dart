import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_state_labels.dart';
import '../../../../shared/widgets/empty_state_view.dart';

/// Shown when the bookmarks list resolves to empty. "Explore restaurants"
/// hops the user back to the Home tab where they can find places to save.
class BookmarksEmptyState extends ConsumerWidget {
  const BookmarksEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLocaleProvider).languageCode;
    final labels = AppStateLabels.of(lang);
    return Center(
      child: EmptyStateView(
        icon: Icons.bookmark_outline_rounded,
        iconCircleColor: EmptyStateView.coralCircle(context),
        title: labels.emptyBookmarksTitle,
        description: labels.emptyBookmarksDescription,
        buttonText: labels.emptyBookmarksCta,
        onButtonPressed: () => context.go(AppRoutes.home),
      ),
    );
  }
}
