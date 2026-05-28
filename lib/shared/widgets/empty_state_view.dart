import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Designed empty / error state — centered icon-in-circle, title,
/// description, and an optional CTA. Used everywhere a screen would
/// otherwise be blank or show a bare error string.
///
/// The icon circle color is passed in (callers pick Coral / gray / error
/// red / amber via [EmptyStateView] static helpers) so the same widget
/// covers both "nothing here yet" and "something broke" without branching
/// internally.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.iconCircleColor,
    required this.title,
    required this.description,
    this.buttonText,
    this.onButtonPressed,
    this.isPrimaryButton = true,
    this.compact = false,
  });

  final IconData icon;
  final Color iconCircleColor;
  final String title;
  final String description;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  /// `true` → Coral filled button; `false` → outlined (used for actions
  /// that leave the app, e.g. "Open settings").
  final bool isPrimaryButton;

  /// Slightly tighter sizing for inline use (e.g. inside the detail
  /// page's reviews section) vs. a full-screen blank.
  final bool compact;

  /// Coral circle — "nothing here yet" prompts (reviews, bookmarks).
  static Color coralCircle(BuildContext context) =>
      AppColors.of(context).primary;

  /// Neutral gray circle — search-empty (not an error, just no match).
  static Color grayCircle(BuildContext context) =>
      AppColors.of(context).textTertiary;

  /// Error-red circle — network / server failures. Brighter in dark mode
  /// so it doesn't sink into the page.
  static Color errorCircle(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFF07070)
          : const Color(0xFFE24B4A);

  /// Amber circle — permission prompts (location). Same tone both modes.
  static Color amberCircle(BuildContext context) => const Color(0xFFF5B85C);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final circleSize = compact ? 64.0 : 80.0;
    final iconSize = compact ? 36.0 : 48.0;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 40,
        vertical: compact ? 24 : 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: iconCircleColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: iconSize, color: iconCircleColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              color: c.textSecondary,
              height: 1.4,
            ),
          ),
          if (buttonText != null && onButtonPressed != null) ...[
            const SizedBox(height: 16),
            isPrimaryButton
                ? _PrimaryButton(label: buttonText!, onTap: onButtonPressed!)
                : _OutlinedButton(label: buttonText!, onTap: onButtonPressed!),
          ],
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: c.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  const _OutlinedButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(color: c.borderSecondary, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: c.textPrimary,
          ),
        ),
      ),
    );
  }
}
