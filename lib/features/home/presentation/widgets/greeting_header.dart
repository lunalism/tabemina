import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';

/// "What's good today?" greeting at the top of the Home feed.
class GreetingHeader extends ConsumerWidget {
  const GreetingHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    final labels = _Labels.of(ref.watch(appLocaleProvider).languageCode);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        topInset + AppConstants.spaceLg,
        AppConstants.spaceLg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labels.greeting,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: c.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            labels.subtitle,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Localized greeting copy (KO / JA / EN) via the project's manual
/// `XxxLabels.of(lang)` convention.
class _Labels {
  const _Labels._({required this.greeting, required this.subtitle});

  final String greeting;
  final String subtitle;

  static _Labels of(String lang) {
    switch (lang) {
      case 'ja':
        return const _Labels._(
          greeting: '今日は何食べる?',
          subtitle: '近くのおいしいお店を見つけよう',
        );
      case 'ko':
        return const _Labels._(
          greeting: '오늘 뭐 먹지?',
          subtitle: '내 주변 맛집을 찾아보세요',
        );
      case 'en':
      default:
        return const _Labels._(
          greeting: "What's good today?",
          subtitle: 'Discover the best eats around you',
        );
    }
  }
}
