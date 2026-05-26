import 'package:flutter/widgets.dart' show Locale;
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

  /// Reverse-geocode a lat/lng to a human "district, city" label, localized
  /// to the app's [locale] (e.g. en → "Marunouchi, Chiyoda", ja →
  /// "丸の内、千代田区").
  ///
  /// `geocoding` exposes locale as a *global* setter rather than a per-call
  /// parameter, so we set it right before each query — cheap, and keeps the
  /// call site honest about which language the placemark is being asked to
  /// return. The country code is paired heuristically with the language so
  /// the placemark API gets a fully qualified identifier (en_US / ja_JP /
  /// ko_KR).
  ///
  /// Falls through the administrative hierarchy because in Japan many wards
  /// return an empty `locality`. If only a city resolves, just the city is
  /// returned; if nothing resolves, `null`.
  Future<String?> getCityName(
    double latitude,
    double longitude, {
    required Locale locale,
  }) async {
    await setLocaleIdentifier(_geocodingLocaleId(locale));
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) return null;
    final p = placemarks.first;

    final district = _firstNonEmpty([
      p.subLocality,
      p.subAdministrativeArea,
    ]);
    final city = _firstNonEmpty([
      p.locality,
      p.administrativeArea,
    ]);

    if (district != null && city != null && district != city) {
      return '$district, $city';
    }
    return city ?? district;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Pair an app [Locale] (just a language code) with a representative
  /// country code so the `geocoding` API gets a fully qualified identifier.
  /// The placemark service tolerates language-only IDs but returns richer
  /// admin labels when both halves are present.
  static String _geocodingLocaleId(Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return 'ja_JP';
      case 'ko':
        return 'ko_KR';
      case 'en':
      default:
        return 'en_US';
    }
  }
}
