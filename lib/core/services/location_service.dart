import 'package:geolocator/geolocator.dart';

/// Thin wrapper around [Geolocator] for one-shot "where am I" reads.
///
/// Centralized so feature widgets don't each have to reinvent the
/// service-enabled / permission-granted / permission-denied-forever ladder.
class LocationService {
  const LocationService();

  /// Returns the device's current position, or `null` if location services are
  /// disabled or the user declined permission. Never throws for the
  /// expected failure modes — callers can treat a `null` result as "no fix,
  /// leave the camera alone."
  Future<Position?> getCurrentPosition() async {
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
}
