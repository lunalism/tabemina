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
    required this.editReview,
    required this.deleteReview,
    required this.deleteReviewConfirmTitle,
    required this.deleteReviewConfirmBody,
    required this.cancel,
    required this.delete,
    required this.reviewDeleted,
    required this.reviewDeleteFailed,
    required this.draftInProgress,
    required this.underReview,
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

  // Review actions (long-press menu + delete confirm)
  final String editReview;
  final String deleteReview;
  final String deleteReviewConfirmTitle;
  final String deleteReviewConfirmBody;
  final String cancel;
  final String delete;
  final String reviewDeleted;
  final String reviewDeleteFailed;

  // Draft hint on the reviews empty state.
  final String draftInProgress;

  /// Muted tag on the user's OWN review when it's been hidden by reports —
  /// shown only on My Page so they understand it was removed from listings.
  final String underReview;

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
    editReview: 'Edit review',
    deleteReview: 'Delete review',
    deleteReviewConfirmTitle: 'Delete review?',
    deleteReviewConfirmBody: 'This action cannot be undone.',
    cancel: 'Cancel',
    delete: 'Delete',
    reviewDeleted: 'Review deleted',
    reviewDeleteFailed: 'Failed to delete. Please try again.',
    draftInProgress: 'You have a draft in progress',
    underReview: 'Under review',
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
    editReview: 'レビューを編集',
    deleteReview: 'レビューを削除',
    deleteReviewConfirmTitle: 'レビューを削除しますか？',
    deleteReviewConfirmBody: 'この操作は取り消せません。',
    cancel: 'キャンセル',
    delete: '削除',
    reviewDeleted: 'レビューを削除しました',
    reviewDeleteFailed: '削除に失敗しました。もう一度お試しください。',
    draftInProgress: '下書きがあります',
    underReview: '審査中',
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
    editReview: '리뷰 수정',
    deleteReview: '리뷰 삭제',
    deleteReviewConfirmTitle: '리뷰를 삭제하시겠습니까?',
    deleteReviewConfirmBody: '이 작업은 되돌릴 수 없습니다.',
    cancel: '취소',
    delete: '삭제',
    reviewDeleted: '리뷰가 삭제되었습니다',
    reviewDeleteFailed: '삭제에 실패했습니다. 다시 시도해주세요.',
    draftInProgress: '작성 중인 임시저장이 있습니다',
    underReview: '검토 중',
  );
}
