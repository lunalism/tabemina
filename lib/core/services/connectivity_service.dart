/// Coarse network reachability state the app reacts to.
///
/// Deliberately binary — features only need "can I reach the network or not",
/// not the transport (wifi/cellular/etc.). Keeping it two-valued means call
/// sites stay simple and the concrete backend can collapse any number of
/// connectivity signals down to this.
enum NetworkStatus { online, offline }

/// Connectivity abstraction the rest of the app depends on.
///
/// Deliberately tiny and backend-agnostic: UI and feature code talk to this
/// interface only, never to `connectivity_plus` directly. That keeps the
/// concrete provider swappable and confines the third-party import to a single
/// implementation file ([ConnectivityPlusService]) — the same pattern as
/// [AnalyticsService] / `FirebaseAnalyticsService`.
abstract class ConnectivityService {
  /// Emits whenever reachability changes. Does not replay the current value on
  /// listen — callers that need an initial value should also call [checkNow]
  /// (the app-global provider seeds with it).
  Stream<NetworkStatus> get onStatusChanged;

  /// One-shot read of the current reachability.
  Future<NetworkStatus> checkNow();
}
