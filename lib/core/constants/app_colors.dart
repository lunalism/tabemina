import 'package:flutter/material.dart';

/// Color tokens for Tabemina.
///
/// The palette is chosen to be CVD-safe (color vision deficiency friendly),
/// avoiding red/green pairings as the sole carrier of meaning. Success states
/// use blue rather than green, and the "error" red is shifted toward a distinct
/// hue that remains distinguishable for users with red-green deficiency.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0066CC); // blue
  static const Color secondary = Color(0xFFE5A00D); // amber

  // Semantic
  static const Color error = Color(0xFFCC3333); // distinct red
  static const Color success = Color(0xFF0066CC); // blue instead of green

  // Rating
  static const Color ratingStar = Color(0xFFE5A00D); // amber

  // Backgrounds
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF1A1A1A);

  // Surfaces
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color surfaceDark = Color(0xFF2A2A2A);

  // Text
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryLight = Color(0xFF666666);
  static const Color textSecondaryDark = Color(0xFF999999);

  // On-color (foreground placed on top of brand/semantic colors)
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFF1A1A1A);
  static const Color onError = Color(0xFFFFFFFF);
}
