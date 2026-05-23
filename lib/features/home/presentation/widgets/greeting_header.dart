import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

/// "What's good today?" greeting at the top of the Home feed.
class GreetingHeader extends StatelessWidget {
  const GreetingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final topInset = MediaQuery.of(context).padding.top;

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
            "What's good today?",
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
            'Discover the best eats around you',
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
