import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_origin.dart';
import '../../../../core/providers/analytics_providers.dart';

/// (placeId, origin) key for [restaurantViewedTrackerProvider].
typedef RestaurantViewedArgs = ({String placeId, AnalyticsOrigin origin});

/// Fires `restaurant_viewed` exactly once per detail open, tagged with the
/// surface it was opened from.
///
/// As an `autoDispose.family` its body runs once when first watched for a given
/// (placeId, origin) and is cached until the screen is popped (no listeners →
/// dispose), so build() re-runs don't re-fire while re-opening the screen does.
/// Complements the id-free automatic `screen_view`.
final restaurantViewedTrackerProvider =
    Provider.autoDispose.family<void, RestaurantViewedArgs>((ref, args) {
  ref.read(analyticsEventsProvider).restaurantViewed(
        restaurantId: args.placeId,
        origin: args.origin,
      );
});
