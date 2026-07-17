import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/utils/keyboard.dart';
import '../providers/search_providers.dart';

/// Horizontally scrollable row of cuisine filter chips.
///
/// Reads / writes [searchFilterProvider] so any other widget (the results
/// list, the markers, the empty state) can react to a filter change without
/// going through this widget.
class FilterChipRow extends ConsumerWidget {
  const FilterChipRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(searchFilterProvider);
    final lang = ref.watch(appLocaleProvider).languageCode;

    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
        itemCount: SearchFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppConstants.spaceSm),
        itemBuilder: (context, i) {
          final filter = SearchFilter.values[i];
          return _FilterChip(
            label: filterChipLabel(filter, lang),
            selected: filter == selected,
            onTap: () {
              // Picking a chip is a switch from typing to browsing —
              // drop the keyboard along with it.
              dismissKeyboard();
              ref.read(searchFilterProvider.notifier).select(filter);
            },
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final borderColor = selected ? c.primary : c.borderSecondary;
    final bgColor =
        selected ? c.primary.withValues(alpha: 0.1) : Colors.transparent;
    final textColor = selected ? c.primary : c.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
