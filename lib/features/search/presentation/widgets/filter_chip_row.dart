import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// Horizontally scrollable row of category filter chips.
///
/// Local state only — the selected index isn't lifted because filters aren't
/// wired into search yet. Lifted-state version comes when the list is real.
class FilterChipRow extends StatefulWidget {
  const FilterChipRow({super.key});

  static const List<String> _labels = [
    'All',
    'Ramen',
    'Sushi',
    'Izakaya',
    'Cafe',
    'Date spot',
    'Budget',
  ];

  @override
  State<FilterChipRow> createState() => _FilterChipRowState();
}

class _FilterChipRowState extends State<FilterChipRow> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
        itemCount: FilterChipRow._labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppConstants.spaceSm),
        itemBuilder: (context, i) {
          return _FilterChip(
            label: FilterChipRow._labels[i],
            selected: i == _selected,
            onTap: () => setState(() => _selected = i),
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
    final bgColor = selected
        ? c.primary.withValues(alpha: 0.1)
        : Colors.transparent;
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
