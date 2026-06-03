/// Curated objectionable-content blocklist, organized by language.
///
/// Stage 0 (client-only, no Cloud Functions) proactive filter for review
/// comments. It complements the reactive layers already shipped: report →
/// auto-hide (B-2-1) and block (B-2-2). Scope is the user-typed comment text
/// only — photos are not text-filterable client-side.
///
/// SEEDING POLICY — keep this CONSERVATIVE. List only clearly objectionable
/// terms (hate slurs, sexually explicit terms, severe profanity). Over-broad
/// lists cause false positives, which is worse than a missed term here (the
/// reactive report/block layers catch the rest). This list is a living
/// document: REVIEW AND EXPAND it over time as real-world abuse surfaces.
///
/// Matching rules (see [ContentFilter]):
///   • [en] is matched on whole-word/token boundaries, so an innocent word that
///     merely *contains* a listed term (e.g. "class" vs "ass", "Scunthorpe" vs
///     "cunt") is NOT flagged. Store entries lowercase, single tokens.
///   • [ko] / [ja] are matched as substrings (no reliable word boundaries), so
///     keep each entry specific enough to minimize false hits.
///
/// Entries are stored already-normalized (lowercase) to match the normalized
/// form the filter compares against.
class ObjectionableTerms {
  ObjectionableTerms._();

  /// English — whole-word matched. Lowercase, single tokens.
  static const List<String> en = [
    'fuck',
    'shit',
    'cunt',
    'asshole',
    'bitch',
    'bastard',
    'slut',
    'whore',
    'rape',
    'rapist',
    'nigger',
    'faggot',
    'retard',
    'pussy',
    'dick',
    'cock',
  ];

  /// Korean — substring matched. Keep specific to avoid false hits.
  static const List<String> ko = [
    '씨발',
    '시발',
    '씨팔',
    '개새끼',
    '병신',
    '지랄',
    '좆',
    '자지',
    '보지',
    '강간',
  ];

  /// Japanese — substring matched. Keep specific to avoid false hits.
  static const List<String> ja = [
    '死ね',
    'きちがい',
    'まんこ',
    'ちんこ',
    'ちんぽ',
    'レイプ',
    'クソ野郎',
  ];
}
