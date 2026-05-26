import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
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
      body: SingleChildScrollView(
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
    );
  }
}
