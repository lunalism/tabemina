import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_typography.dart';

/// Material 3 themes for Tabemina — Coral warm-tone palette (light + dark).
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppColors.light, Brightness.light);

  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: AppColors.onPrimary,
      secondary: c.secondary,
      onSecondary: c.textPrimary,
      error: c.errorText,
      onError: AppColors.onPrimary,
      surface: c.bgCard,
      onSurface: c.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.bgPage,
      dividerColor: c.borderPrimary,
      fontFamily: AppTypography.fontFamily,
      textTheme: AppTypography.textTheme.apply(
        bodyColor: c.textPrimary,
        displayColor: c.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bgPage,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.bgCard,
        selectedItemColor: c.tabActive,
        unselectedItemColor: c.tabInactive,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        color: c.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
        ),
      ),
    );
  }
}
