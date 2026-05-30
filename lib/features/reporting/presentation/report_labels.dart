import '../../../domain/entities/report_reason.dart';

/// Localized copy for the review-reporting surface (EN/JA/KO).
///
/// Follows the project's manual-localization convention (`XxxLabels.of(lang)`)
/// since the app has no gen-l10n/.arb pipeline. Tone is deliberately calm and
/// neutral — reporting should feel measured, not alarming.
class ReportLabels {
  const ReportLabels._({
    required this.sheetTitle,
    required this.reasonSpam,
    required this.reasonOffensive,
    required this.reasonHate,
    required this.reasonOffTopic,
    required this.reasonOther,
    required this.cancel,
    required this.success,
    required this.alreadyReported,
    required this.failed,
  });

  final String sheetTitle;
  final String reasonSpam;
  final String reasonOffensive;
  final String reasonHate;
  final String reasonOffTopic;
  final String reasonOther;
  final String cancel;
  final String success;
  final String alreadyReported;
  final String failed;

  /// Label for a given reason in the current language.
  String labelFor(ReportReason reason) => switch (reason) {
    ReportReason.spam => reasonSpam,
    ReportReason.offensive => reasonOffensive,
    ReportReason.hate => reasonHate,
    ReportReason.offTopic => reasonOffTopic,
    ReportReason.other => reasonOther,
  };

  static ReportLabels of(String lang) {
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

  static const _en = ReportLabels._(
    sheetTitle: 'Report review',
    reasonSpam: 'Spam or fake review',
    reasonOffensive: 'Offensive or inappropriate content',
    reasonHate: 'Hate speech or harassment',
    reasonOffTopic: 'Off-topic / not about this place',
    reasonOther: 'Other',
    cancel: 'Cancel',
    success: "Thanks for letting us know. We'll take a look.",
    alreadyReported: 'You already reported this review',
    failed: "Couldn't submit your report. Please try again.",
  );

  static const _ja = ReportLabels._(
    sheetTitle: 'レビューを報告',
    reasonSpam: 'スパムまたは偽のレビュー',
    reasonOffensive: '不快または不適切なコンテンツ',
    reasonHate: 'ヘイトスピーチや嫌がらせ',
    reasonOffTopic: 'この店と関係のない内容',
    reasonOther: 'その他',
    cancel: 'キャンセル',
    success: 'ご報告ありがとうございます。確認いたします。',
    alreadyReported: 'このレビューはすでに報告済みです',
    failed: '報告を送信できませんでした。もう一度お試しください。',
  );

  static const _ko = ReportLabels._(
    sheetTitle: '리뷰 신고',
    reasonSpam: '스팸 또는 가짜 리뷰',
    reasonOffensive: '불쾌하거나 부적절한 콘텐츠',
    reasonHate: '혐오 발언 또는 괴롭힘',
    reasonOffTopic: '장소와 관련 없는 내용',
    reasonOther: '기타',
    cancel: '취소',
    success: '알려주셔서 감사합니다. 검토하겠습니다.',
    alreadyReported: '이미 신고한 리뷰입니다',
    failed: '신고를 전송하지 못했습니다. 다시 시도해 주세요.',
  );
}
