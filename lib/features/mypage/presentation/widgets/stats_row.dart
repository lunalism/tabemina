import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../mypage_labels.dart';

/// Four-up stat cards under the profile header: Reviews / Saved / Visited /
/// Helpful. Counts are passed in (the screen already watches the providers)
/// so this widget stays presentational and doesn't double-subscribe.
class StatsRow extends StatelessWidget {
  const StatsRow({
    super.key,
    required this.labels,
    required this.reviews,
    required this.saved,
    required this.visited,
    required this.helpful,
  });

  final MyPageLabels labels;
  final int reviews;
  final int saved;
  final int visited;
  final int helpful;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.rate_review_outlined,
              value: reviews,
              label: labels.statsReviews,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              icon: Icons.bookmark_outline,
              value: saved,
              label: labels.statsSaved,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              icon: Icons.place_outlined,
              value: visited,
              label: labels.statsVisited,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatCard(
              icon: Icons.thumb_up_outlined,
              value: helpful,
              label: labels.statsHelpful,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderPrimary, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: c.textSecondary),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 11,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
