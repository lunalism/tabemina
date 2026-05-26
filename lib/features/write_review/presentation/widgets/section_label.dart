import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Section header reused across photo / rating / tag / comment.
///
/// Carries a leading icon, the section name, and a small required/optional
/// pill on the right. Keeping it in one place avoids the slow drift that
/// usually happens when each section reimplements its own label.
class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.icon,
    required this.label,
    this.badgeText,
    this.badgeRequired = false,
  });

  final IconData icon;
  final String label;
  final String? badgeText;
  final bool badgeRequired;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: c.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: c.textPrimary,
          ),
        ),
        if (badgeText != null) ...[
          const SizedBox(width: 6),
          _Badge(text: badgeText!, required: badgeRequired),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.required});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bg = required ? c.primary : c.bgSkeleton;
    final fg = required ? AppColors.onPrimary : c.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}
