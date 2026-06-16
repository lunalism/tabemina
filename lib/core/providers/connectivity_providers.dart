import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/connectivity_plus_service.dart';
import '../services/connectivity_service.dart';

/// Shared [ConnectivityService] singleton.
///
/// Exposes the ABSTRACT type so callers depend on the contract, not the
/// `connectivity_plus` implementation — swap the body here to change backends
/// without touching a single call site.
final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityPlusService(),
);

/// App-global stream of [NetworkStatus].
///
/// Seeds with the current status via [ConnectivityService.checkNow] before
/// yielding live changes, so launch reflects the real state instead of flashing
/// offline. `distinct()` collapses duplicate emissions (e.g. wifi→wifi+vpn that
/// both map to online).
///
/// NOT autoDispose on purpose: this is app-global and must stay alive for the
/// whole app lifetime so transient subscriptions don't tear down the listener.
final connectivityStatusProvider = StreamProvider<NetworkStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);

  Stream<NetworkStatus> combined() async* {
    yield await service.checkNow();
    yield* service.onStatusChanged;
  }

  return combined().distinct();
});
