/// Localized copy for the post-sign-in EULA consent gate (EN/JA/KO).
///
/// Manual-localization convention (`XxxLabels.of(lang)`) — the project has no
/// ARB pipeline. The body carries the App Store Guideline 1.2 zero-tolerance
/// statement; the decline action reads as such from its label, not its color.
class EulaLabels {
  const EulaLabels._({
    required this.title,
    required this.body,
    required this.termsOfUse,
    required this.privacyPolicy,
    required this.agreeAndContinue,
    required this.decline,
    required this.saveFailed,
  });

  /// Friendly welcome headline.
  final String title;

  /// Consent body, including the zero-tolerance sentence.
  final String body;

  /// Tappable link labels.
  final String termsOfUse;
  final String privacyPolicy;

  /// Primary / secondary action labels.
  final String agreeAndContinue;
  final String decline;

  /// Shown when recording consent fails (offline / transient error).
  final String saveFailed;

  static EulaLabels of(String lang) {
    switch (lang) {
      case 'ja':
        return _ja;
      case 'ko':
        return _ko;
      case 'en':
      default:
        return _en;
    }
  }

  static const _en = EulaLabels._(
    title: 'Welcome to Tabemina',
    body:
        'By continuing, you agree to our Terms of Use and Privacy Policy. '
        'Tabemina has zero tolerance for objectionable content and abusive '
        'users.',
    termsOfUse: 'Terms of Use',
    privacyPolicy: 'Privacy Policy',
    agreeAndContinue: 'Agree and continue',
    decline: 'Decline',
    saveFailed: "Couldn't save your consent. Please try again.",
  );

  static const _ja = EulaLabels._(
    title: 'Tabemina へようこそ',
    body:
        '続行すると、利用規約とプライバシーポリシーに同意したものとみなされます。Tabemina は、不適切なコンテンツや'
        '迷惑行為を行うユーザーを一切容認しません。',
    termsOfUse: '利用規約',
    privacyPolicy: 'プライバシーポリシー',
    agreeAndContinue: '同意して続ける',
    decline: '同意しない',
    saveFailed: '同意を保存できませんでした。もう一度お試しください。',
  );

  static const _ko = EulaLabels._(
    title: 'Tabemina에 오신 것을 환영합니다',
    body:
        '계속하면 이용약관과 개인정보 처리방침에 동의하는 것으로 간주됩니다. Tabemina는 부적절한 콘텐츠와 '
        '불쾌감을 주는 사용자를 절대 용납하지 않습니다.',
    termsOfUse: '이용약관',
    privacyPolicy: '개인정보 처리방침',
    agreeAndContinue: '동의하고 계속하기',
    decline: '동의 안 함',
    saveFailed: '동의를 저장하지 못했습니다. 다시 시도해 주세요.',
  );
}
