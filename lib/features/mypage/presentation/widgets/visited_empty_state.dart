import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../mypage_labels.dart';

/// Empty state for the "Visited" tab (a v2 feature) — place-pin in a gray
/// circle with a "coming soon" message and no CTA.
class VisitedEmptyState extends StatelessWidget {
  const VisitedEmptyState({super.key, required this.labels});

  final MyPageLabels labels;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: c.textTertiary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.place_outlined, size: 40, color: c.textTertiary),
          ),
          const SizedBox(height: 12),
          Text(
            labels.noVisitedPlaces,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            labels.visitedComingSoon,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              color: c.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
