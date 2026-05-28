/// Localized copy for every empty / error state in the app, in EN / JA / KO.
///
/// Follows the project's established manual-localization convention
/// (`XxxLabels.of(lang)`) rather than gen-l10n, since the app has no
/// `AppLocalizations` / `.arb` pipeline and drives language off
/// `appLocaleProvider`. One table keeps the shared strings (e.g. the
/// "Try again" CTA) from drifting between screens.
class AppStateLabels {
  const AppStateLabels({
    required this.emptyReviewsTitle,
    required this.emptyReviewsDescription,
    required this.emptyReviewsCta,
    required this.emptyBookmarksTitle,
    required this.emptyBookmarksDescription,
    required this.emptyBookmarksCta,
    required this.emptySearchTitle,
    required this.emptySearchDescription,
    required this.emptyDetailReviewsTitle,
    required this.emptyDetailReviewsDescription,
    required this.emptyDetailReviewsCta,
    required this.errorNetworkTitle,
    required this.errorNetworkDescription,
    required this.errorNetworkCta,
    required this.errorServerTitle,
    required this.errorServerDescription,
    required this.errorServerCta,
    required this.errorLocationTitle,
    required this.errorLocationDescription,
    required this.errorLocationCta,
  });

  // 1a — My Reviews empty
  final String emptyReviewsTitle;
  final String emptyReviewsDescription;
  final String emptyReviewsCta;

  // 1b — Bookmarks empty
  final String emptyBookmarksTitle;
  final String emptyBookmarksDescription;
  final String emptyBookmarksCta;

  // 1c — Search no results
  final String emptySearchTitle;
  final String emptySearchDescription;

  // 1d — Detail Tabemina reviews empty
  final String emptyDetailReviewsTitle;
  final String emptyDetailReviewsDescription;
  final String emptyDetailReviewsCta;

  // 2a — Network error
  final String errorNetworkTitle;
  final String errorNetworkDescription;
  final String errorNetworkCta;

  // 2b — Server error / timeout
  final String errorServerTitle;
  final String errorServerDescription;
  final String errorServerCta;

  // 2c — Location permission denied
  final String errorLocationTitle;
  final String errorLocationDescription;
  final String errorLocationCta;

  static AppStateLabels of(String lang) {
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

  static const _en = AppStateLabels(
    emptyReviewsTitle: 'No reviews yet',
    emptyReviewsDescription:
        'Share your first food experience! It only takes 30 seconds.',
    emptyReviewsCta: 'Write first review',
    emptyBookmarksTitle: 'No saved places',
    emptyBookmarksDescription:
        'Tap the bookmark icon on any restaurant to save it here.',
    emptyBookmarksCta: 'Explore restaurants',
    emptySearchTitle: 'No results found',
    emptySearchDescription: 'Try a different keyword or check the spelling.',
    emptyDetailReviewsTitle: 'No reviews yet',
    emptyDetailReviewsDescription: 'Be the first to share your experience!',
    emptyDetailReviewsCta: 'Write a review',
    errorNetworkTitle: 'No internet connection',
    errorNetworkDescription: 'Check your connection and try again.',
    errorNetworkCta: 'Try again',
    errorServerTitle: 'Something went wrong',
    errorServerDescription: 'Please try again in a moment.',
    errorServerCta: 'Try again',
    errorLocationTitle: 'Location access needed',
    errorLocationDescription:
        'Enable location access to find restaurants near you.',
    errorLocationCta: 'Open settings',
  );

  static const _ja = AppStateLabels(
    emptyReviewsTitle: 'まだレビューがありません',
    emptyReviewsDescription: '最初の食体験をシェアしましょう！30秒で完了します。',
    emptyReviewsCta: '最初のレビューを書く',
    emptyBookmarksTitle: '保存した場所がありません',
    emptyBookmarksDescription: 'レストランのブックマークアイコンをタップして保存しましょう。',
    emptyBookmarksCta: 'レストランを探す',
    emptySearchTitle: '結果が見つかりません',
    emptySearchDescription: '別のキーワードで検索するか、スペルを確認してください。',
    emptyDetailReviewsTitle: 'まだレビューがありません',
    emptyDetailReviewsDescription: '最初にあなたの体験をシェアしましょう！',
    emptyDetailReviewsCta: 'レビューを書く',
    errorNetworkTitle: 'インターネット接続がありません',
    errorNetworkDescription: '接続を確認してもう一度お試しください。',
    errorNetworkCta: 'もう一度試す',
    errorServerTitle: '問題が発生しました',
    errorServerDescription: 'しばらくしてからもう一度お試しください。',
    errorServerCta: 'もう一度試す',
    errorLocationTitle: '位置情報の許可が必要です',
    errorLocationDescription: '近くのレストランを見つけるには位置情報を有効にしてください。',
    errorLocationCta: '設定を開く',
  );

  static const _ko = AppStateLabels(
    emptyReviewsTitle: '아직 리뷰가 없어요',
    emptyReviewsDescription: '첫 번째 맛집 경험을 공유해보세요! 30초면 돼요.',
    emptyReviewsCta: '첫 리뷰 쓰기',
    emptyBookmarksTitle: '저장한 곳이 없어요',
    emptyBookmarksDescription: '음식점의 북마크 아이콘을 탭해서 저장해보세요.',
    emptyBookmarksCta: '맛집 둘러보기',
    emptySearchTitle: '검색 결과가 없어요',
    emptySearchDescription: '다른 키워드로 검색하거나 맞춤법을 확인해보세요.',
    emptyDetailReviewsTitle: '아직 리뷰가 없어요',
    emptyDetailReviewsDescription: '첫 번째로 경험을 공유해보세요!',
    emptyDetailReviewsCta: '리뷰 쓰기',
    errorNetworkTitle: '인터넷 연결이 없어요',
    errorNetworkDescription: '연결을 확인하고 다시 시도해주세요.',
    errorNetworkCta: '다시 시도',
    errorServerTitle: '문제가 발생했어요',
    errorServerDescription: '잠시 후 다시 시도해주세요.',
    errorServerCta: '다시 시도',
    errorLocationTitle: '위치 권한이 필요해요',
    errorLocationDescription: '근처 맛집을 찾으려면 위치 권한을 허용해주세요.',
    errorLocationCta: '설정 열기',
  );
}
