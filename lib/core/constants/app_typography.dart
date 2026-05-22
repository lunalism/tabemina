import 'package:flutter/material.dart';

/// Typography tokens for Tabemina.
///
/// Uses the Pretendard font family (declared in `pubspec.yaml`, files under
/// `assets/fonts/`). The scale is tuned for mixed Japanese / Korean / English
/// content: line height is 1.5 throughout for comfortable CJK readability, and
/// letter spacing stays near zero (slightly tightened only on large titles) to
/// avoid distorting CJK glyph rhythm.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Pretendard';

  // Weight tokens (map to the registered Pretendard assets).
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  /// 1.5 line height keeps CJK glyphs from crowding vertically.
  static const double _cjkHeight = 1.5;

  static const TextTheme textTheme = TextTheme(
    // Screen titles
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: bold,
      height: _cjkHeight,
      letterSpacing: -0.5,
    ),
    // Section headers
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: semiBold,
      height: _cjkHeight,
      letterSpacing: -0.25,
    ),
    // Card titles
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 18,
      fontWeight: semiBold,
      height: _cjkHeight,
      letterSpacing: 0,
    ),
    // Body text
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: regular,
      height: _cjkHeight,
      letterSpacing: 0,
    ),
    // Secondary text
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: regular,
      height: _cjkHeight,
      letterSpacing: 0,
    ),
    // Button labels
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: medium,
      height: _cjkHeight,
      letterSpacing: 0.1,
    ),
    // Captions, badges
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: medium,
      height: _cjkHeight,
      letterSpacing: 0.2,
    ),
  );
}
