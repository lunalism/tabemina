import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';

/// Riverpod provider for the shared [LocationService] singleton.
final locationServiceProvider = Provider<LocationService>(
  (ref) => const LocationService(),
);

/// One-shot fetch of the device's current GPS position.
///
/// `null` means "we couldn't get a fix" — either location services are off or
/// the user denied permission. The provider is cached for the session so every
/// feature that needs the user's location triggers at most one OS call.
final currentPositionProvider = FutureProvider<Position?>((ref) {
  return ref.watch(locationServiceProvider).getCurrentPosition();
});

/// City label derived from [currentPositionProvider] via reverse geocoding.
///
/// `null` when there's no position or no resolvable placemark; the UI shows
/// a "Locating..." fallback in that case.
final currentCityProvider = FutureProvider<String?>((ref) async {
  final position = await ref.watch(currentPositionProvider.future);
  if (position == null) return null;
  return ref
      .read(locationServiceProvider)
      .getCityName(position.latitude, position.longitude);
});
