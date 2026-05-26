import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_locale_provider.dart';

/// User-facing appearance options: follow the device, or force one of the two
/// hand-built themes.
enum AppThemeMode { system, light, dark }

/// Currently active appearance mode, persisted across launches.
///
/// Stored as a single short string in SharedPreferences so an unknown value
/// (e.g. from a future build that adds new modes) gracefully falls back to
/// [AppThemeMode.system] rather than crashing.
class AppThemeModeNotifier extends Notifier<AppThemeMode> {
  static const _prefsKey = 'app_theme_mode';

  @override
  AppThemeMode build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getString(_prefsKey);
    return _decode(saved);
  }

  Future<void> set(AppThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_prefsKey, _encode(mode));
  }

  static AppThemeMode _decode(String? value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }

  static String _encode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }
}

final appThemeModeProvider =
    NotifierProvider<AppThemeModeNotifier, AppThemeMode>(
  AppThemeModeNotifier.new,
);

/// Map the app's choice to the Flutter framework's [ThemeMode].
ThemeMode flutterThemeModeFor(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.system:
      return ThemeMode.system;
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
  }
}

/// Localized label for the My Page row trailing value and the modal options.
String themeModeDisplayName(AppThemeMode mode, String languageCode) {
  switch (languageCode) {
    case 'ja':
      switch (mode) {
        case AppThemeMode.system:
          return 'システム';
        case AppThemeMode.light:
          return 'ライト';
        case AppThemeMode.dark:
          return 'ダーク';
      }
    case 'ko':
      switch (mode) {
        case AppThemeMode.system:
          return '시스템';
        case AppThemeMode.light:
          return '라이트';
        case AppThemeMode.dark:
          return '다크';
      }
    case 'en':
    default:
      switch (mode) {
        case AppThemeMode.system:
          return 'System';
        case AppThemeMode.light:
          return 'Light';
        case AppThemeMode.dark:
          return 'Dark';
      }
  }
}

IconData themeModeIcon(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.system:
      return Icons.phone_iphone_rounded;
    case AppThemeMode.light:
      return Icons.wb_sunny_outlined;
    case AppThemeMode.dark:
      return Icons.dark_mode_outlined;
  }
}
