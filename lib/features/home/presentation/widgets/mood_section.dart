import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// "Browse by mood" — horizontally scrolling row of theme chips.
///
/// Tapping a chip is a no-op for now; the filter wiring lands with the
/// mood-filtered restaurant query.
class MoodSection extends StatelessWidget {
  const MoodSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.space2xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Header(),
          SizedBox(height: AppConstants.spaceSm),
          _Chips(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 18, color: c.accent),
          const SizedBox(width: 6),
          Text(
            'Browse by mood',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips();

  // Mood-icon accents are theme-agnostic design colors — the same coral, green,
  // blue, etc. render in both modes. Solo / Budget pick the two existing brand
  // coral constants; the others aren't in the palette and live here.
  static const _amber = Color(0xFFF5B85C);
  static const _green = Color(0xFF5DCAA5);
  static const _blue = Color(0xFF85B7EB);
  static const _purple = Color(0xFFB088F9);

  @override
  Widget build(BuildContext context) {
    const moods = <_Mood>[
      _Mood(
        Icons.person_outline,
        AppColors.brandCoralDark,
        'Solo dining',
        '42 spots',
      ),
      _Mood(Icons.favorite_border, _amber, 'Date night', '28 spots'),
      _Mood(Icons.groups_outlined, _green, 'Family', '35 spots'),
      _Mood(Icons.work_outline, _blue, 'Business', '19 spots'),
      _Mood(
        Icons.account_balance_wallet_outlined,
        AppColors.brandCoralLight,
        'Budget',
        '56 spots',
      ),
      _Mood(
        Icons.auto_awesome_outlined,
        _purple,
        'Special occasion',
        '15 spots',
      ),
    ];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(
          left: AppConstants.spaceLg,
          right: AppConstants.spaceLg,
        ),
        itemCount: moods.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppConstants.spaceSm),
        itemBuilder: (_, i) => _MoodChip(mood: moods[i]),
      ),
    );
  }
}

@immutable
class _Mood {
  const _Mood(this.icon, this.color, this.name, this.spots);
  final IconData icon;
  final Color color;
  final String name;
  final String spots;
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.mood});

  final _Mood mood;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
      decoration: BoxDecoration(
        color: c.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.borderPrimary, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: mood.color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(mood.icon, size: 16, color: mood.color),
          ),
          const SizedBox(width: AppConstants.spaceSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mood.name,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                mood.spots,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 10,
                  color: c.textSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
