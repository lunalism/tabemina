/// Developer-only overrides.
///
/// Set [useDevLocation] to `false` for production builds.
class DevConfig {
  DevConfig._();

  /// When `true`, [LocationService.getCurrentPosition] returns
  /// [devLat] / [devLng] instead of the real GPS fix. Useful when
  /// developing the Japan restaurant app from outside Japan.
  static const bool useDevLocation = true;

  /// Dev coordinates — Tokyo Station.
  static const double devLat = 35.6812;
  static const double devLng = 139.7671;
}
