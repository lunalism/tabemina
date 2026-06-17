import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_locale_provider.dart';
import '../../../../shared/widgets/app_state_labels.dart';
import '../../../../shared/widgets/empty_state_view.dart';

/// Shown inside the search bottom sheet while the device is offline (B-3-3-2).
///
/// A calm, passive state — no retry CTA, since the ambient amber offline banner
/// already signals connectivity globally and search resumes on its own once
/// back online. Reuses the A-2 [EmptyStateView] so it matches every other
/// empty/error state rather than inventing a new look.
class SearchOfflineState extends ConsumerWidget {
  const SearchOfflineState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = AppStateLabels.of(ref.watch(appLocaleProvider).languageCode);
    return EmptyStateView(
      icon: Icons.wifi_off_rounded,
      // Amber (not error-red) keeps it calm and ties it to the offline banner.
      iconCircleColor: EmptyStateView.amberCircle(context),
      // Search-specific title (the amber banner already says "you're offline").
      title: labels.searchOfflineTitle,
      description: labels.offlineSearch,
      compact: true,
    );
  }
}
