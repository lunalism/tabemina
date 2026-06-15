/// Compiler-enforced vocabulary for the `origin` analytics parameter — the
/// surface from which a tracked action was initiated.
///
/// Each value's [wireValue] is the exact string sent to analytics. These MUST
/// stay stable: `bookmarkList` matches the `'bookmark_list'` first shipped in
/// STEP 3-2, so there's no data discontinuity. Add new values additively
/// (never renaming an existing wire string).
enum AnalyticsOrigin {
  homeFeed('home_feed'),
  searchResult('search_result'),
  mapPin('map_pin'),
  bookmarkList('bookmark_list'),
  restaurantDetail('restaurant_detail'),
  myPage('my_page'),
  deepLink('deep_link');

  const AnalyticsOrigin(this.wireValue);

  /// The literal string logged for this origin.
  final String wireValue;

  /// Resolves a GoRouter `state.extra` to an origin, defaulting to [deepLink]
  /// when absent or of an unexpected type — covers deep links, state restore,
  /// and programmatic pushes that carry no origin.
  static AnalyticsOrigin fromExtra(Object? extra) =>
      extra is AnalyticsOrigin ? extra : AnalyticsOrigin.deepLink;
}
