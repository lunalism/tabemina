/// Localized copy for the Restaurant Detail action chrome (KO / JA / EN),
/// following the project's manual `XxxLabels.of(lang)` convention.
///
/// The "Review" and "Write review" labels are NOT defined here — they reuse
/// `NavLabels.review` / `NavLabels.writeReview` so the verbs stay identical to
/// the bottom navigation. This table holds only the detail-specific labels:
/// the secondary action buttons, the hours chip, the rating-count suffix, and
/// the deleted-place (not-found) state.
class DetailLabels {
  const DetailLabels._(
    this._lang, {
    required this.save,
    required this.route,
    required this.share,
    required this.openNow,
    required this.closed,
    required this.notFoundTitle,
    required this.notFoundDescription,
    required this.notFoundBack,
  });

  final String _lang;

  /// Bookmark-toggle action button.
  final String save;

  /// Open the maps/route sheet.
  final String route;

  /// Share the place.
  final String share;

  /// Open-status chip when the place is currently open / closed.
  final String openNow;
  final String closed;

  /// Deleted-place state (Places 404): title, body, and the single
  /// back-navigation button — deliberately no retry, it can never succeed.
  final String notFoundTitle;
  final String notFoundDescription;
  final String notFoundBack;

  /// "({n} reviews)" suffix next to the rating.
  String reviewCount(int n) {
    switch (_lang) {
      case 'ja':
        return '(レビュー$n件)';
      case 'ko':
        return '(리뷰 $n개)';
      default:
        return '($n reviews)';
    }
  }

  static DetailLabels of(String lang) {
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

  static const _en = DetailLabels._(
    'en',
    save: 'Save',
    route: 'Route',
    share: 'Share',
    openNow: 'Open now',
    closed: 'Closed',
    notFoundTitle: 'This restaurant is no longer available',
    notFoundDescription: 'It may have closed or been removed from the map.',
    notFoundBack: 'Go back',
  );

  static const _ja = DetailLabels._(
    'ja',
    save: '保存',
    route: '経路',
    share: 'シェア',
    openNow: '営業中',
    closed: '閉店',
    notFoundTitle: 'このお店は表示できません',
    notFoundDescription: '閉店したか、地図から削除された可能性があります。',
    notFoundBack: '戻る',
  );

  static const _ko = DetailLabels._(
    'ko',
    save: '저장',
    route: '길찾기',
    share: '공유',
    openNow: '영업 중',
    closed: '영업 종료',
    notFoundTitle: '더 이상 확인할 수 없는 가게예요',
    notFoundDescription: '폐업했거나 지도에서 삭제되었을 수 있어요.',
    notFoundBack: '돌아가기',
  );
}
