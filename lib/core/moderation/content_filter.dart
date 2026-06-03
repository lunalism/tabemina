import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'objectionable_terms.dart';

/// Client-side objectionable-content filter for review comments (App Store
/// Guideline 1.2). Pure and stateless — given the same text it always returns
/// the same verdict, so it's trivially testable and swappable.
///
/// Matching strategy:
///   1. Normalize: Unicode NFKC (folds full-width / compatibility forms used to
///      evade filters) → lowercase → collapse runs of 3+ identical characters
///      to one (so "fuuuuck" matches "fuck").
///   2. English: match on whole-word/token boundaries, defeating the
///      "Scunthorpe problem" — an innocent word that merely contains a blocked
///      substring (e.g. "class", "Scunthorpe") is never flagged.
///   3. Korean / Japanese: substring match, since those scripts have no
///      reliable word boundaries. The blocklist keeps such terms specific.
///   4. The text is checked against ALL THREE language lists — a review may be
///      written in any language regardless of the app's UI language.
class ContentFilter {
  const ContentFilter({
    this.en = ObjectionableTerms.en,
    this.ko = ObjectionableTerms.ko,
    this.ja = ObjectionableTerms.ja,
  });

  final List<String> en;
  final List<String> ko;
  final List<String> ja;

  /// Whether [text] contains an objectionable term from any language list.
  bool isBlocked(String text) {
    if (text.trim().isEmpty) return false;
    final normalized = _normalize(text);

    // Korean / Japanese — substring match (no word boundaries).
    for (final term in ko) {
      if (normalized.contains(term)) return true;
    }
    for (final term in ja) {
      if (normalized.contains(term)) return true;
    }

    // English — whole-word match against the token set.
    final tokens = _tokenize(normalized);
    for (final term in en) {
      if (term.contains(' ')) {
        // Multi-word phrase: anchor on ASCII word boundaries.
        if (RegExp('\\b${RegExp.escape(term)}\\b').hasMatch(normalized)) {
          return true;
        }
      } else if (tokens.contains(term)) {
        return true;
      }
    }
    return false;
  }

  /// NFKC + lowercase + collapse excessive character repetition.
  String _normalize(String text) {
    final folded = unorm.nfkc(text).toLowerCase();
    // Reduce any run of 3+ identical characters to a single one. This catches
    // elongation evasion ("shiiit" → "shit") without touching legitimate
    // double letters ("letter", "cool"), which stay below the threshold.
    return folded.replaceAllMapped(RegExp(r'(.)\1{2,}'), (m) => m[1]!);
  }

  /// Split normalized text into alphanumeric tokens for whole-word matching.
  Set<String> _tokenize(String normalized) {
    return normalized
        .split(RegExp('[^a-z0-9]+'))
        .where((t) => t.isNotEmpty)
        .toSet();
  }
}

/// Shared filter instance. Override in tests to inject a custom blocklist.
final contentFilterProvider = Provider<ContentFilter>((ref) {
  return const ContentFilter();
});
