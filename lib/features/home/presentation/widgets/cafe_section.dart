import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../shared/widgets/app_state_labels.dart';
import '../providers/popular_restaurants_provider.dart';
import 'popular_card_skeleton.dart';
import 'popular_restaurant_card.dart';

/// "Cafes nearby" — same horizontal carousel as the popular section, but
/// driven by [nearbyCafesProvider] (cafes / bakeries / dessert shops).
///
/// Visually distinguished by a warm-brown coffee-cup icon on the header so
/// the cafe row reads differently from the coral-flame popular row.
class CafeSection extends ConsumerWidget {
  const CafeSection({super.key});

  static const double _carouselHeight = 192;

  // Header coffee-cup tint — warm brown to contrast against the coral primary
  // already used by the Popular section. One-off design accents; intentionally
  // not promoted into [AppColors].
  static const _coffeeBrownDark = Color(0xFFC4956A);
  static const _coffeeBrownLight = Color(0xFF8B6A47);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(appLocaleProvider).languageCode;
    final labels = _Labels.of(lang);
    final retryLabel = AppStateLabels.of(lang).errorNetworkCta;
    final async = ref.watch(nearbyCafesProvider);

    return Padding(
      padding: const EdgeInsets.only(top: AppConstants.spaceXl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(title: labels.title, seeAll: labels.seeAll),
          const SizedBox(height: AppConstants.spaceSm),
          SizedBox(
            height: _carouselHeight,
            child: async.when(
              loading: () => const _LoadingRow(),
              error: (_, _) => _ErrorState(
                message: labels.errorMessage,
                retryLabel: retryLabel,
                onRetry: () => ref.invalidate(nearbyCafesProvider),
              ),
              data: (items) => items.isEmpty
                  ? _EmptyState(message: labels.emptyMessage)
                  : _Carousel(items: items),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.seeAll});

  final String title;
  final String seeAll;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? CafeSection._coffeeBrownDark
        : CafeSection._coffeeBrownLight;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        0,
        AppConstants.spaceLg,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.local_cafe_outlined, size: 18, color: iconColor),
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
          const Spacer(),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceXs,
                vertical: 2,
              ),
              child: Text(
                seeAll,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Carousel extends StatelessWidget {
  const _Carousel({required this.items});

  final List items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (context, i) {
        return PopularRestaurantCard(rank: i + 1, restaurant: items[i]);
      },
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  static const _opacities = [1.0, 0.5, 0.2];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
      itemCount: _opacities.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, i) => PopularCardSkeleton(opacity: _opacities[i]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_outlined, size: 32, color: c.textTertiary),
          const SizedBox(height: AppConstants.spaceSm),
          Text(
            message,
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 13,
              color: c.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.spaceSm),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: c.primary,
              side: BorderSide(color: c.primary),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              ),
            ),
            child: Text(
              retryLabel,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Localized section chrome for "Cafes nearby" (KO / JA / EN). The "See all"
/// value matches the Popular / Latest-reviews sections so the affordance reads
/// identically across the Home feed; the Retry CTA reuses [AppStateLabels].
class _Labels {
  const _Labels._({
    required this.title,
    required this.seeAll,
    required this.emptyMessage,
    required this.errorMessage,
  });

  final String title;
  final String seeAll;
  final String emptyMessage;
  final String errorMessage;

  static _Labels of(String lang) {
    switch (lang) {
      case 'ja':
        return const _Labels._(
          title: '近くのカフェ',
          seeAll: 'すべて表示 >',
          emptyMessage: '近くにカフェが見つかりません',
          errorMessage: 'カフェを読み込めませんでした',
        );
      case 'ko':
        return const _Labels._(
          title: '근처 카페',
          seeAll: '모두 보기 >',
          emptyMessage: '근처에 카페가 없어요',
          errorMessage: '카페를 불러올 수 없어요',
        );
      case 'en':
      default:
        return const _Labels._(
          title: 'Cafes nearby',
          seeAll: 'See all >',
          emptyMessage: 'No cafes found nearby',
          errorMessage: "Couldn't load cafes",
        );
    }
  }
}
