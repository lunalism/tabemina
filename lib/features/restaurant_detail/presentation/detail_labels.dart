/// Localized copy for the Restaurant Detail action chrome (KO / JA / EN),
/// following the project's manual `XxxLabels.of(lang)` convention.
///
/// The "Review" and "Write review" labels are NOT defined here — they reuse
/// `NavLabels.review` / `NavLabels.writeReview` so the verbs stay identical to
/// the bottom navigation. This table holds only the detail-specific labels:
/// the secondary action buttons, the hours chip, and the rating-count suffix.
class DetailLabels {
  const DetailLabels._(
    this._lang, {
    required this.save,
    required this.route,
    required this.share,
    required this.openNow,
    required this.closed,
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
  );

  static const _ja = DetailLabels._(
    'ja',
    save: '保存',
    route: '経路',
    share: 'シェア',
    openNow: '営業中',
    closed: '閉店',
  );

  static const _ko = DetailLabels._(
    'ko',
    save: '저장',
    route: '길찾기',
    share: '공유',
    openNow: '영업 중',
    closed: '영업 종료',
  );
}
