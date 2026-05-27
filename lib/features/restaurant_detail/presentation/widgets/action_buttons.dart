import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/bookmark_pulse.dart';

/// Four-up action row under the info header: Review / Save / Route / Share.
///
/// The "Review" CTA is filled with a faint coral tint so it reads as the
/// primary action — the rest are outline so they don't compete with the
/// fixed bottom bar's "Write review" button.
class ActionButtons extends StatelessWidget {
  const ActionButtons({
    super.key,
    required this.onReview,
    required this.onSave,
    required this.onRoute,
    required this.onShare,
    required this.saved,
  });

  final VoidCallback onReview;
  final VoidCallback onSave;
  final VoidCallback onRoute;
  final VoidCallback onShare;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        AppConstants.spaceLg,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.edit_outlined,
              label: 'Review',
              filled: true,
              color: c.primary,
              onTap: onReview,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: BookmarkPulse(
              saved: saved,
              child: _ActionButton(
                icon: saved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                label: 'Save',
                color: saved ? c.primary : c.textSecondary,
                onTap: onSave,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              icon: Icons.navigation_outlined,
              label: 'Route',
              color: c.textSecondary,
              onTap: onRoute,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ActionButton(
              icon: Icons.share_outlined,
              label: 'Share',
              color: c.textSecondary,
              onTap: onShare,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: 0.1) : null,
          border: Border.all(color: c.borderPrimary, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 11,
                fontWeight: filled ? FontWeight.w500 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
