import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../write_review/domain/models/tag_definitions.dart';

/// "Browse by mood" — horizontally scrolling row of theme chips.
///
/// Tapping a chip is a no-op for now; the filter wiring lands with the
/// mood-filtered restaurant query. All copy is localized via [_MoodLabels],
/// which reuses the review-form [tagLabel] table for the mood names.
class MoodSection extends ConsumerWidget {
  const MoodSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = _MoodLabels.of(ref.watch(appLocaleProvider).languageCode);
    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.space2xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(title: labels.title),
          const SizedBox(height: AppConstants.spaceSm),
          _Chips(labels: labels),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

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
            title,
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
  const _Chips({required this.labels});

  final _MoodLabels labels;

  // Mood-icon accents are theme-agnostic design colors — the same coral, green,
  // blue, etc. render in both modes. Solo / Budget pick the two existing brand
  // coral constants; the others aren't in the palette and live here.
  static const _amber = Color(0xFFF5B85C);
  static const _green = Color(0xFF5DCAA5);
  static const _blue = Color(0xFF85B7EB);
  static const _purple = Color(0xFFB088F9);

  @override
  Widget build(BuildContext context) {
    final moods = <_Mood>[
      _Mood(
        Icons.person_outline,
        AppColors.brandCoralDark,
        labels.solo,
        labels.spots(42),
      ),
      _Mood(Icons.favorite_border, _amber, labels.date, labels.spots(28)),
      _Mood(Icons.groups_outlined, _green, labels.family, labels.spots(35)),
      _Mood(Icons.work_outline, _blue, labels.business, labels.spots(19)),
      _Mood(
        Icons.account_balance_wallet_outlined,
        AppColors.brandCoralLight,
        labels.budget,
        labels.spots(56),
      ),
      _Mood(
        Icons.auto_awesome_outlined,
        _purple,
        labels.specialOccasion,
        labels.spots(15),
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

/// Localized copy for the Browse-by-mood section (KO / JA / EN), following the
/// project's manual `XxxLabels.of(lang)` convention.
///
/// Mood NAMES reuse the review-form [tagLabel] table for KO/JA so translations
/// live in one place (혼밥/ひとり, 데이트/デート, 가족/ファミリー, …). Only the
/// descriptive EN phrasing for solo/date and the brand-new "Special occasion"
/// category are defined here.
class _MoodLabels {
  const _MoodLabels(
    this._lang, {
    required this.title,
    required this.specialOccasion,
  });

  final String _lang;

  /// Section header ("Browse by mood").
  final String title;

  /// "Special occasion" — no matching review-form tag, so localized here.
  final String specialOccasion;

  String get solo => _lang == 'en' ? 'Solo dining' : tagLabel('solo', _lang);
  String get date => _lang == 'en' ? 'Date night' : tagLabel('date', _lang);
  String get family => tagLabel('family', _lang);
  String get business => tagLabel('business', _lang);
  String get budget => tagLabel('budget', _lang);

  /// Localized "{n} spots" count suffix.
  String spots(int n) {
    switch (_lang) {
      case 'ko':
        return '$n곳';
      case 'ja':
        return '$n件';
      default:
        return '$n spots';
    }
  }

  static _MoodLabels of(String code) {
    switch (code) {
      case 'ja':
        return const _MoodLabels('ja', title: '気分で探す', specialOccasion: '特別な日');
      case 'ko':
        return const _MoodLabels(
          'ko',
          title: '무드별 둘러보기',
          specialOccasion: '특별한 날',
        );
      case 'en':
      default:
        return const _MoodLabels(
          'en',
          title: 'Browse by mood',
          specialOccasion: 'Special occasion',
        );
    }
  }
}
