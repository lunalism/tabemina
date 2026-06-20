import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../presentation/providers/review_providers.dart';
import '../../../../shared/widgets/nav_compact_scroller.dart';
import '../../../../shared/widgets/tab_scaffold.dart';
import '../providers/popular_restaurants_provider.dart';
import '../widgets/cafe_section.dart';
import '../widgets/greeting_header.dart';
import '../widgets/latest_reviews_section.dart';
import '../widgets/location_pill.dart';
import '../widgets/popular_section.dart';

/// Home feed — vertically scrolling stack of sections.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bgPage,
      body: NavCompactScroller(
        child: RefreshIndicator(
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
            // Clear the floating nav bar so the last section is reachable.
            padding: EdgeInsets.only(bottom: floatingNavContentInset(context)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GreetingHeader(),
                LocationPill(),
                PopularSection(),
                CafeSection(),
                LatestReviewsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
