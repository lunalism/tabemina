import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the floating bottom nav is in its COMPACT (shrunk) state.
///
/// Default false (expanded). Driven true when the user scrolls a tab screen
/// down, and back to false on scroll-up or near the top. The bar always stays
/// visible — it only shrinks, never hides.
class NavCompactNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// Set compactness, ignoring no-op writes so scroll events don't churn.
  void set(bool compact) {
    if (state != compact) state = compact;
  }
}

final navCompactProvider = NotifierProvider<NavCompactNotifier, bool>(
  NavCompactNotifier.new,
);
