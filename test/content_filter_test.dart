import 'package:flutter_test/flutter_test.dart';
import 'package:tabemina/core/moderation/content_filter.dart';

/// Pure-logic verification of the B-2-3-2 objectionable-content filter.
/// Covers the three verification passes that don't need the device.
void main() {
  const filter = ContentFilter();

  group('blocks objectionable terms (Pass 1)', () {
    test('English term', () {
      expect(filter.isBlocked('what the fuck is this'), isTrue);
    });
    test('Korean term', () {
      expect(filter.isBlocked('진짜 씨발 맛없어'), isTrue);
    });
    test('Japanese term', () {
      expect(filter.isBlocked('まじで死ねって感じ'), isTrue);
    });
    test('elongation evasion is caught', () {
      expect(filter.isBlocked('this is shiiiiit'), isTrue);
    });
    test('full-width evasion is caught via NFKC', () {
      // Full-width Latin "fuck".
      expect(filter.isBlocked('ｆｕｃｋ'), isTrue);
    });
    test('uppercase is caught', () {
      expect(filter.isBlocked('FUCK this'), isTrue);
    });
  });

  group('passes clean text & avoids false positives (Pass 2)', () {
    test('normal clean comment', () {
      expect(filter.isBlocked('Amazing ramen, loved the broth!'), isFalse);
    });
    test('empty / whitespace', () {
      expect(filter.isBlocked(''), isFalse);
      expect(filter.isBlocked('   '), isFalse);
    });
    test('Scunthorpe problem — substring is not a whole word', () {
      expect(filter.isBlocked('We visited Scunthorpe last week'), isFalse);
      expect(filter.isBlocked('a great class on cooking'), isFalse);
      expect(filter.isBlocked('the assassin role in the play'), isFalse);
      expect(filter.isBlocked('grass-fed beef and a cocktail'), isFalse);
    });
    test('clean Korean / Japanese comments', () {
      expect(filter.isBlocked('정말 맛있어요 또 올게요'), isFalse);
      expect(filter.isBlocked('とても美味しかったです'), isFalse);
    });
  });
}
