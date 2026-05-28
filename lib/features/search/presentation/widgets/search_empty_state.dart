import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_locale_provider.dart';
import '../../../../shared/widgets/app_state_labels.dart';
import '../../../../shared/widgets/empty_state_view.dart';

/// Shown inside the bottom sheet when a text search returns zero hits.
/// No CTA — the user just types a new query.
class SearchEmptyState extends ConsumerWidget {
  const SearchEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLocaleProvider).languageCode;
    final labels = AppStateLabels.of(lang);
    return EmptyStateView(
      icon: Icons.search_off_rounded,
      iconCircleColor: EmptyStateView.grayCircle(context),
      title: labels.emptySearchTitle,
      description: labels.emptySearchDescription,
      compact: true,
    );
  }
}
