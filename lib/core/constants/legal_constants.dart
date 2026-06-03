/// App-wide legal/consent constants.
///
/// The hosted Terms and Privacy pages are trilingual (KO/JA/EN) and switch
/// language via a `?lang=` query param whose values (`ko`/`ja`/`en`) match the
/// app's own language codes one-to-one — so [legalUrlForLang] just appends the
/// active `languageCode`.
class LegalConstants {
  LegalConstants._();

  /// Current EULA revision, kept in lockstep with the "Last updated" date on
  /// the hosted legal pages. Bumping this re-prompts every user for consent
  /// (their stored accepted version no longer equals this value).
  static const String eulaVersion = '2026.06.03';

  /// Hosted legal pages (GitHub Pages). Both accept a `?lang=` param.
  static const String termsOfUseUrl =
      'https://lunalism.github.io/tabemina/terms.html';
  static const String privacyPolicyUrl =
      'https://lunalism.github.io/tabemina/privacy.html';

  /// Append the active app language so the page opens showing that single
  /// language with its in-page toggle hidden. App language codes (en/ja/ko)
  /// map directly onto the page's `?lang=` values.
  static String legalUrlForLang(String baseUrl, String languageCode) =>
      '$baseUrl?lang=$languageCode';

  /// Published support contact (App Store Guideline 1.2). Surfaced in Settings
  /// and openable via a `mailto:` composer.
  static const String supportEmail = 'chrisholic11@gmail.com';

  /// Default subject line prefilled into the support mail composer.
  static const String supportEmailSubject = 'Tabemina Support';

  /// `mailto:` URL for the support address with the subject prefilled. The
  /// subject is percent-encoded so spaces survive across mail clients.
  static String supportMailtoUrl() =>
      'mailto:$supportEmail?subject=${Uri.encodeComponent(supportEmailSubject)}';
}
