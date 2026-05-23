import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/location_providers.dart';

/// Inline pill that shows the user's resolved city (e.g. "Tokyo") with a
/// map-pin glyph. Falls back to "Locating..." while reverse geocoding runs
/// or when no fix is available.
class LocationPill extends ConsumerWidget {
  const LocationPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final city = ref.watch(currentCityProvider);
    final label = city.maybeWhen(
      data: (name) => name ?? 'Locating...',
      orElse: () => 'Locating...',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceSm,
        AppConstants.spaceLg,
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: c.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.borderPrimary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place_outlined, size: 14, color: c.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
