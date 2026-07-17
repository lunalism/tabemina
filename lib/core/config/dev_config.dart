/// Developer-only overrides.
class DevConfig {
  DevConfig._();

  /// When `true`, [LocationService.getCurrentPosition] returns
  /// [devLat] / [devLng] instead of the real GPS fix. Useful when
  /// developing the Japan restaurant app from outside Japan.
  ///
  /// Off in every build unless explicitly activated with
  /// `--dart-define=DEV_LOCATION=true` (works with `flutter run` and
  /// `flutter build`), so a release build can never ship with the
  /// override on by accident.
  static const bool useDevLocation = bool.fromEnvironment('DEV_LOCATION');

  /// Dev coordinates — Tokyo Station.
  static const double devLat = 35.6812;
  static const double devLng = 139.7671;
}
