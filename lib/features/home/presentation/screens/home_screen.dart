import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../presentation/providers/review_providers.dart';
import '../providers/popular_restaurants_provider.dart';
import '../widgets/ad_banner_section.dart';
import '../widgets/cafe_section.dart';
import '../widgets/greeting_header.dart';
import '../widgets/latest_reviews_section.dart';
import '../widgets/location_pill.dart';
import '../widgets/mood_section.dart';
import '../widgets/popular_section.dart';

/// Home feed — vertically scrolling stack of sections.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bgPage,
      body: RefreshIndicator(
        color: c.primary,
        backgroundColor: c.bgCard,
        // Re-fetch the network-backed sections. Static/local sections
        // (greeting, location pill, mood) don't need invalidation. Reading
        // .future on each provider gives us a join point so the spinner
        // hides only once everything is actually back.
        onRefresh: () async {
          ref.invalidate(popularRestaurantsProvider);
          ref.invalidate(nearbyCafesProvider);
          ref.invalidate(latestReviewsProvider);
          await Future.wait([
            ref.read(popularRestaurantsProvider.future),
            ref.read(nearbyCafesProvider.future),
            ref.read(latestReviewsProvider.future),
          ]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              GreetingHeader(),
              LocationPill(),
              PopularSection(),
              AdBannerSection(),
              CafeSection(),
              MoodSection(),
              LatestReviewsSection(),
              SizedBox(height: AppConstants.space2xl),
            ],
          ),
        ),
      ),
    );
  }
}
