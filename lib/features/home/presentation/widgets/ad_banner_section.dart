import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// App-promo banner shown between the popular and cafe sections.
///
/// Acts as the placeholder slot for paid ads — when real ad inventory lands,
/// the parent should branch on the ad-availability check and render
/// [AdBannerSection] only as the fallback for the "no ad" case. For now there
/// is no paid inventory, so we always show one of three rotating Tabemina
/// promos.
///
/// The blue gradient is deliberately different from the warm-coral gradient
/// any future sponsored banner will use, so users can read at a glance
/// whether the slot is paid or first-party.
class AdBannerSection extends StatelessWidget {
  const AdBannerSection({super.key});

  // One-off promo gradient — kept local to this widget so the token set in
  // [AppColors] doesn't get polluted by surface-specific accents.
  static const _gradientDark = [Color(0xFF1A2A3A), Color(0xFF0C2A4A)];
  static const _gradientLight = [Color(0xFFEEF4FF), Color(0xFFD6E8FF)];

  static const List<_Promo> _promos = [
    _Promo(
      title: 'Share your foodie story',
      subtitle: 'Write a 30-second review and help fellow travelers',
      cta: 'Write a review',
    ),
    _Promo(
      title: 'Discover hidden gems',
      subtitle: 'Browse restaurants by mood — solo, date, family & more',
      cta: 'Explore moods',
    ),
    _Promo(
      title: 'New here? Welcome!',
      subtitle: 'Tabemina helps you find the best eats with real reviews',
      cta: 'Get started',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? _gradientDark : _gradientLight;
    final promo = _promos[Random().nextInt(_promos.length)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceXl,
        AppConstants.spaceLg,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spaceLg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TABEMINA',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    promo.title,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    promo.subtitle,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.spaceMd),
            _CtaButton(label: promo.cta),
          ],
        ),
      ),
    );
  }
}

@immutable
class _Promo {
  const _Promo({
    required this.title,
    required this.subtitle,
    required this.cta,
  });

  final String title;
  final String subtitle;
  final String cta;
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: c.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}
