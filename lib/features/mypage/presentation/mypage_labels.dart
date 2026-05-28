/// Localized copy for the My Page screen and its sub-widgets, in EN/JA/KO.
///
/// Follows the project's manual-localization convention (`XxxLabels.of(lang)`)
/// since the app has no gen-l10n/.arb pipeline and drives language off
/// `appLocaleProvider`. Promoted out of the screen file so the stats row,
/// photo grid, and empty-state widgets can share it.
class MyPageLabels {
  const MyPageLabels({
    required this.guestTitle,
    required this.guestSubtitle,
    required this.signIn,
    required this.signOut,
    required this.signedOutSnack,
    required this.fallbackName,
    required this.settingsHeader,
    required this.languageLabel,
    required this.appearanceLabel,
    required this.versionLabel,
    required this.editProfile,
    required this.myReviewsTab,
    required this.savedTab,
    required this.visitedTab,
    required this.statsReviews,
    required this.statsSaved,
    required this.statsVisited,
    required this.statsHelpful,
    required this.noReviewsYet,
    required this.noReviewsDesc,
    required this.writeFirstReview,
    required this.noVisitedPlaces,
    required this.visitedComingSoon,
  });

  final String guestTitle;
  final String guestSubtitle;
  final String signIn;
  final String signOut;
  final String signedOutSnack;
  final String fallbackName;
  final String settingsHeader;
  final String languageLabel;
  final String appearanceLabel;
  final String versionLabel;

  // New (this rebuild)
  final String editProfile;
  final String myReviewsTab;
  final String savedTab;
  final String visitedTab;
  final String statsReviews;
  final String statsSaved;
  final String statsVisited;
  final String statsHelpful;
  final String noReviewsYet;
  final String noReviewsDesc;
  final String writeFirstReview;
  final String noVisitedPlaces;
  final String visitedComingSoon;

  static MyPageLabels of(String lang) {
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

  static const _en = MyPageLabels(
    guestTitle: 'Guest User',
    guestSubtitle: 'Sign in to access your profile',
    signIn: 'Sign in',
    signOut: 'Sign out',
    signedOutSnack: 'Signed out',
    fallbackName: 'Tabemina user',
    settingsHeader: 'Settings',
    languageLabel: 'Language',
    appearanceLabel: 'Appearance',
    versionLabel: 'Version',
    editProfile: 'Edit profile',
    myReviewsTab: 'My reviews',
    savedTab: 'Saved',
    visitedTab: 'Visited',
    statsReviews: 'Reviews',
    statsSaved: 'Saved',
    statsVisited: 'Visited',
    statsHelpful: 'Helpful',
    noReviewsYet: 'No reviews yet',
    noReviewsDesc:
        'Share your first food experience! It only takes 30 seconds.',
    writeFirstReview: 'Write first review',
    noVisitedPlaces: 'No visited places',
    visitedComingSoon: "Coming soon! We'll track your food adventures.",
  );

  static const _ja = MyPageLabels(
    guestTitle: 'ゲストユーザー',
    guestSubtitle: 'プロフィールにアクセスするにはログインしてください',
    signIn: 'ログイン',
    signOut: 'ログアウト',
    signedOutSnack: 'ログアウトしました',
    fallbackName: 'Tabemina ユーザー',
    settingsHeader: '設定',
    languageLabel: '言語',
    appearanceLabel: 'テーマ',
    versionLabel: 'バージョン',
    editProfile: 'プロフィール編集',
    myReviewsTab: 'マイレビュー',
    savedTab: '保存済み',
    visitedTab: '訪問済み',
    statsReviews: 'レビュー',
    statsSaved: '保存',
    statsVisited: '訪問',
    statsHelpful: '参考',
    noReviewsYet: 'レビューはまだありません',
    noReviewsDesc: '最初のグルメ体験をシェアしましょう！30秒で完了します。',
    writeFirstReview: '最初のレビューを書く',
    noVisitedPlaces: '訪問した場所はありません',
    visitedComingSoon: '近日公開！あなたのグルメ冒険を記録します。',
  );

  static const _ko = MyPageLabels(
    guestTitle: '게스트 사용자',
    guestSubtitle: '프로필에 접근하려면 로그인하세요',
    signIn: '로그인',
    signOut: '로그아웃',
    signedOutSnack: '로그아웃했습니다',
    fallbackName: 'Tabemina 사용자',
    settingsHeader: '설정',
    languageLabel: '언어',
    appearanceLabel: '테마',
    versionLabel: '버전',
    editProfile: '프로필 수정',
    myReviewsTab: '내 리뷰',
    savedTab: '저장됨',
    visitedTab: '방문함',
    statsReviews: '리뷰',
    statsSaved: '저장',
    statsVisited: '방문',
    statsHelpful: '도움',
    noReviewsYet: '아직 리뷰가 없습니다',
    noReviewsDesc: '첫 맛집 경험을 공유해보세요! 30초면 충분합니다.',
    writeFirstReview: '첫 리뷰 쓰기',
    noVisitedPlaces: '방문한 곳이 없습니다',
    visitedComingSoon: '곧 제공 예정! 당신의 미식 여정을 기록할게요.',
  );
}
