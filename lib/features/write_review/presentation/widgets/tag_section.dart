import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/tag_definitions.dart';
import 'section_label.dart';

/// Two category groups of selectable chips: mood / price.
///
/// Selection lives in the parent screen as a `Set<String>` of tag keys;
/// this widget only renders. Chips wrap (Wrap layout) instead of scrolling
/// so the user can see the whole catalogue at a glance. Genre used to live
/// here but was dropped — Google already tells us the cuisine via
/// `primaryType`, so re-asking the user added friction without signal.
class TagSection extends StatelessWidget {
  const TagSection({
    super.key,
    required this.languageCode,
    required this.selected,
    required this.onToggle,
    required this.l,
  });

  final String languageCode;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final TagSectionLabels l;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            icon: Icons.local_offer_outlined,
            label: l.title,
            badgeText: l.requiredBadge,
            badgeRequired: true,
          ),
          const SizedBox(height: AppConstants.spaceSm),
          _Group(
            icon: Icons.favorite_outline_rounded,
            label: categoryLabel(TagCategory.mood, languageCode),
            tags: _tagsIn(TagCategory.mood),
            languageCode: languageCode,
            selected: selected,
            onToggle: onToggle,
          ),
          const SizedBox(height: AppConstants.spaceMd),
          _Group(
            icon: Icons.payments_outlined,
            label: categoryLabel(TagCategory.price, languageCode),
            tags: _tagsIn(TagCategory.price),
            languageCode: languageCode,
            selected: selected,
            onToggle: onToggle,
            withPriceHint: true,
          ),
        ],
      ),
    );
  }

  static List<TagDefinition> _tagsIn(TagCategory category) {
    return kAllTags.where((t) => t.category == category).toList();
  }
}

class TagSectionLabels {
  const TagSectionLabels({required this.title, required this.requiredBadge});

  final String title;
  final String requiredBadge;
}

class _Group extends StatelessWidget {
  const _Group({
    required this.icon,
    required this.label,
    required this.tags,
    required this.languageCode,
    required this.selected,
    required this.onToggle,
    this.withPriceHint = false,
  });

  final IconData icon;
  final String label;
  final List<TagDefinition> tags;
  final String languageCode;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final bool withPriceHint;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: c.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                color: c.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final tag in tags)
              _Chip(
                label: tagLabel(tag.key, languageCode),
                hint: withPriceHint ? kPriceHints[tag.key] : null,
                selected: selected.contains(tag.key),
                onTap: () => onToggle(tag.key),
              ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.hint,
  });

  final String label;
  final String? hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedBg = isDark
        ? const Color(0xFF3A1A0F)
        : const Color(0xFFFFF0EB);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? c.primary : c.borderPrimary,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 12, color: c.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                color: selected ? c.primary : c.textPrimary,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(width: 4),
              Text(
                hint!,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 11,
                  color: selected ? c.primary : c.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
