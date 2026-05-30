import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Reports needed before a user review auto-hides. Stage 0 (solo dev,
/// client-side moderation) uses 1 so a single report hides a review
/// immediately, satisfying App Store UGC moderation at launch. Bump this
/// when auto-hide moves to Cloud Functions (stage 1).
const int kReportThreshold = 1;

/// App-wide constants: spacing, radii, sizing, durations, and map defaults.
class AppConstants {
  AppConstants._();

  // Spacing scale (4pt grid)
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double space2xl = 24;

  // Border radii
  static const double radiusSm = 6;
  static const double radiusMd = 10;
  static const double radiusLg = 16;
  static const double radiusXl = 22;
  static const double radiusFull = 9999;

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
