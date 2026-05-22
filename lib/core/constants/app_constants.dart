import 'package:google_maps_flutter/google_maps_flutter.dart';

/// App-wide constants: spacing, sizing, radii, and durations.
class AppConstants {
  AppConstants._();

  // Spacing scale (4pt grid)
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;

  // Border radii
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  // Sizing
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 32;

  static const double bottomNavHeight = 64;
  static const double reviewFabSize = 56;

  // Animation
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);

  // Map defaults — Tokyo (Tokyo Station area)
  static const LatLng tokyoCenter = LatLng(35.6812, 139.7671);
  static const double defaultMapZoom = 14;
}
