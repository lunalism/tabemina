import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/analytics_service.dart';
import '../services/firebase_analytics_service.dart';

/// Shared [AnalyticsService] singleton.
///
/// Exposes the ABSTRACT type so callers depend on the contract, not the
/// Firebase implementation — swap the body here to change backends without
/// touching a single call site.
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => FirebaseAnalyticsService(),
);

/// Side-effect provider that fires a single `app_start` event the first time
/// it's read, then stays cached for the session (so it logs exactly once).
///
/// This is a plumbing sanity check — it proves the AnalyticsService →
/// FirebaseAnalytics pipe is connected on launch. Real per-screen / per-feature
/// event logging is intentionally NOT done here.
final appStartAnalyticsProvider = Provider<void>((ref) {
  ref.read(analyticsServiceProvider).logEvent('app_start');
});
