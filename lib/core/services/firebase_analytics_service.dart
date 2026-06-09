import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics_service.dart';

/// Firebase-backed [AnalyticsService].
///
/// This is the ONLY file in the app that imports `firebase_analytics`. Keeping
/// the dependency here means the rest of the codebase stays decoupled from the
/// vendored, IDFA-free analytics package and from Firebase's call conventions.
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logScreenView(String screenName) {
    return _analytics.logScreenView(screenName: screenName);
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) {
    return _analytics.logEvent(name: name, parameters: parameters);
  }

  @override
  Future<void> setUserId(String? id) {
    return _analytics.setUserId(id: id);
  }
}
