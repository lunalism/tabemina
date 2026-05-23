import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../config/dev_config.dart';

/// Thin wrapper around [Geolocator] and [Geocoding] for one-shot
/// "where am I / what's that called" reads.
///
/// Centralized so feature widgets don't each have to reinvent the
/// service-enabled / permission-granted / permission-denied-forever ladder.
class LocationService {
  const LocationService();

  /// Returns the device's current position, or `null` if location services are
  /// disabled or the user declined permission. Never throws for the
  /// expected failure modes — callers can treat a `null` result as "no fix,
  /// leave the camera alone."
  ///
  /// When [DevConfig.useDevLocation] is `true` this short-circuits to the
  /// configured dev coordinates without prompting for permission or hitting
  /// the GPS — every caller (Home pill, Popular fetch, Search GPS button)
  /// transparently picks up the override.
  Future<Position?> getCurrentPosition() async {
    if (DevConfig.useDevLocation) return _devPosition();

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Position _devPosition() {
    return Position(
      latitude: DevConfig.devLat,
      longitude: DevConfig.devLng,
      timestamp: DateTime.now(),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  /// Reverse-geocode a lat/lng to a human city label. Falls through the
  /// administrative hierarchy (locality → subAdmin → admin) because in Japan
  /// many wards return an empty `locality`.
  Future<String?> getCityName(double latitude, double longitude) async {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) return null;
    final p = placemarks.first;
    for (final value in [
      p.locality,
      p.subAdministrativeArea,
      p.administrativeArea,
    ]) {
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}
