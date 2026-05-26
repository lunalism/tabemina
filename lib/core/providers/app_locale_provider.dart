import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory handle on [SharedPreferences].
///
/// Overridden in `main()` with the awaited instance so every consumer can read
/// preferences synchronously — no async boilerplate at call sites. Throws if
/// not overridden so misuse fails loudly during development.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  );
});

/// User-facing app languages for v1.0.
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('ja'),
  Locale('ko'),
];

/// Currently active app locale, persisted across launches.
///
/// Watch this anywhere the UI needs to react to language changes (e.g. the
/// reverse-geocoded location pill). Mutate via
/// `ref.read(appLocaleProvider.notifier).set(locale)`.
class AppLocaleNotifier extends Notifier<Locale> {
  static const _prefsKey = 'app_locale';

  @override
  Locale build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      for (final locale in kSupportedLocales) {
        if (locale.languageCode == saved) return locale;
      }
    }
    return const Locale('en');
  }

  Future<void> set(Locale locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(
  AppLocaleNotifier.new,
);

/// Human-readable display name for a supported locale (rendered in MyPage and
/// the language modal). Keyed by language code so adding a new locale only
/// requires an extra map entry.
String localeDisplayName(Locale locale) {
  switch (locale.languageCode) {
    case 'ja':
      return '日本語';
    case 'ko':
      return '한국어';
    case 'en':
    default:
      return 'English';
  }
}

/// Country-flag emoji paired with each locale in the language modal.
String localeFlagEmoji(Locale locale) {
  switch (locale.languageCode) {
    case 'ja':
      return '🇯🇵';
    case 'ko':
      return '🇰🇷';
    case 'en':
    default:
      return '🇺🇸';
  }
}
