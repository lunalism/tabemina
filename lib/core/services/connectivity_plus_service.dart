import 'package:connectivity_plus/connectivity_plus.dart';

import 'connectivity_service.dart';

/// `connectivity_plus`-backed [ConnectivityService].
///
/// This is the ONLY file in the app that imports `connectivity_plus`. Keeping
/// the dependency here means the rest of the codebase stays decoupled from the
/// plugin and its call conventions (mirrors `FirebaseAnalyticsService` being the
/// sole `firebase_analytics` importer).
class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Stream<NetworkStatus> get onStatusChanged =>
      _connectivity.onConnectivityChanged.map(_mapResults);

  @override
  Future<NetworkStatus> checkNow() async =>
      _mapResults(await _connectivity.checkConnectivity());

  /// connectivity_plus v6+ reports a LIST of active transports. Treat an empty
  /// list — or one containing only [ConnectivityResult.none] — as offline; any
  /// real transport means online.
  NetworkStatus _mapResults(List<ConnectivityResult> results) {
    final hasConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );
    return hasConnection ? NetworkStatus.online : NetworkStatus.offline;
  }
}
