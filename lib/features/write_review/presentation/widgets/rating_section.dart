import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import 'section_label.dart';

/// 5-star rating row with localized adjective feedback.
///
/// Tapping the same star twice resets the rating to 0 (mirrors Apple's
/// review widget). Haptic feedback fires per tap so the gesture feels
/// physical even when the visual change is subtle.
class RatingSection extends StatelessWidget {
  const RatingSection({
    super.key,
    required this.rating,
    required this.onChanged,
    required this.l,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final RatingSectionLabels l;

  // Star tint stays the same across themes — amber reads as "rating gold"
  // regardless of background.
  static const _starColor = Color(0xFFF5B85C);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            icon: Icons.star_outline_rounded,
            label: l.title,
            badgeText: l.requiredBadge,
            badgeRequired: true,
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Row(
            children: [
              for (int i = 1; i <= 5; i++) ...[
                _StarButton(
                  filled: i <= rating,
                  color: i <= rating ? _starColor : c.borderSecondary,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onChanged(i == rating ? 0 : i);
                  },
                ),
                if (i < 5) const SizedBox(width: 8),
              ],
            ],
          ),
          if (rating > 0) ...[
            const SizedBox(height: 4),
            _FeedbackText(rating: rating, l: l),
          ],
        ],
      ),
    );
  }
}

class RatingSectionLabels {
  const RatingSectionLabels({
    required this.title,
    required this.requiredBadge,
    required this.adjectives,
    required this.outOf,
  });

  final String title;
  final String requiredBadge;

  /// 1-indexed map: 1..5 → "Poor"/"Fair"/...
  final Map<int, String> adjectives;
  final String Function(int n) outOf;
}

class _StarButton extends StatelessWidget {
  const _StarButton({
    required this.filled,
    required this.color,
    required this.onTap,
  });

  final bool filled;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 32,
          color: color,
        ),
      ),
    );
  }
}

class _FeedbackText extends StatelessWidget {
  const _FeedbackText({required this.rating, required this.l});

  final int rating;
  final RatingSectionLabels l;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final adjective = l.adjectives[rating] ?? '';
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          color: c.textSecondary,
        ),
        children: [
          TextSpan(text: '${l.outOf(rating)} — '),
          TextSpan(
            text: adjective,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: c.primary,
            ),
          ),
        ],
      ),
    );
  }
}
