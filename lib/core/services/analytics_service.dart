/// Analytics abstraction the rest of the app depends on.
///
/// Deliberately tiny and backend-agnostic: UI and feature code talk to this
/// interface only, never to `firebase_analytics` directly. That keeps the
/// concrete provider swappable (Firebase today, anything tomorrow) and keeps
/// the vendored `firebase_analytics` import confined to a single
/// implementation file ([FirebaseAnalyticsService]).
abstract class AnalyticsService {
  /// Records that the user landed on a named screen.
  Future<void> logScreenView(String screenName);

  /// Records an arbitrary named event with optional structured parameters.
  Future<void> logEvent(String name, {Map<String, Object>? parameters});

  /// Associates subsequent events with a user id, or clears it when [id] is
  /// `null` (e.g. on sign-out).
  Future<void> setUserId(String? id);
}
