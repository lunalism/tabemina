import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../widgets/greeting_header.dart';
import '../widgets/location_pill.dart';
import '../widgets/popular_section.dart';

/// Home feed — vertically scrolling stack of sections.
///
/// Phase 2-A wires up the greeting, the location pill, and the
/// "Popular near you" Places-backed carousel. The ad banner, theme chips,
/// and latest-reviews block are reserved as fixed-height placeholders so
/// the scroll geometry doesn't shift when phase 2-B lands.
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
            // Phase 2-B placeholders — fixed heights so the feed geometry
            // is stable across the two phases.
            SizedBox(height: 120), // ad banner
            SizedBox(height: 80), // browse by mood
            SizedBox(height: 300), // latest reviews
            SizedBox(height: AppConstants.space2xl),
          ],
        ),
      ),
    );
  }
}
