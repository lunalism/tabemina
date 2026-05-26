/// Tag catalogue for the write-review form, grouped by category and
/// localized into English / Japanese / Korean.
///
/// Internal storage uses the English `key` so the data layer doesn't need to
/// re-translate before persisting. The UI looks up the localized `label`
/// via [tagLabel].
///
/// Genre was dropped — the restaurant's cuisine is already known from
/// Google's `primaryType`, so re-asking the user just slowed the
/// 30-second flow without adding signal.
library;

/// One of the two category buckets the chip list groups by.
enum TagCategory { mood, price }

class TagDefinition {
  const TagDefinition({required this.key, required this.category});

  /// Stable English identifier used in storage / analytics. Never localized.
  final String key;
  final TagCategory category;
}

const List<TagDefinition> kAllTags = [
  // Mood
  TagDefinition(key: 'solo', category: TagCategory.mood),
  TagDefinition(key: 'date', category: TagCategory.mood),
  TagDefinition(key: 'group', category: TagCategory.mood),
  TagDefinition(key: 'business', category: TagCategory.mood),
  TagDefinition(key: 'family', category: TagCategory.mood),
  TagDefinition(key: 'quiet', category: TagCategory.mood),
  TagDefinition(key: 'lively', category: TagCategory.mood),

  // Price
  TagDefinition(key: 'budget', category: TagCategory.price),
  TagDefinition(key: 'mid', category: TagCategory.price),
  TagDefinition(key: 'high', category: TagCategory.price),
  TagDefinition(key: 'premium', category: TagCategory.price),
];

/// Three-language label table. Default is English so unknown keys at least
/// render something readable.
const Map<String, Map<String, String>> _tagLabels = {
  // Mood
  'solo': {'en': 'Solo', 'ja': 'ひとり', 'ko': '혼밥'},
  'date': {'en': 'Date', 'ja': 'デート', 'ko': '데이트'},
  'group': {'en': 'Group', 'ja': 'グループ', 'ko': '단체'},
  'business': {'en': 'Business', 'ja': 'ビジネス', 'ko': '비즈니스'},
  'family': {'en': 'Family', 'ja': 'ファミリー', 'ko': '가족'},
  'quiet': {'en': 'Quiet', 'ja': '静か', 'ko': '조용한'},
  'lively': {'en': 'Lively', 'ja': 'にぎやか', 'ko': '활기찬'},

  // Price (label only — price ranges live separately so we can localize the
  // yen / won amount without re-keying the chip)
  'budget': {'en': 'Budget', 'ja': '安め', 'ko': '저렴'},
  'mid': {'en': 'Mid', 'ja': '普通', 'ko': '보통'},
  'high': {'en': 'High', 'ja': '高め', 'ko': '비쌈'},
  'premium': {'en': 'Premium', 'ja': '高級', 'ko': '프리미엄'},
};

String tagLabel(String key, String languageCode) {
  final entry = _tagLabels[key];
  if (entry == null) return key;
  return entry[languageCode] ?? entry['en'] ?? key;
}

/// Approximate yen-range hint shown under each price chip. Constant across
/// languages — the digits read the same and adding "~¥1,000" doesn't
/// translate naturally.
const Map<String, String> kPriceHints = {
  'budget': '~¥1,000',
  'mid': '~¥3,000',
  'high': '~¥5,000',
  'premium': '¥10,000~',
};

/// Section-header labels for each category, per language. Kept out of the
/// per-tag table so a new tag doesn't need to update three header lines.
String categoryLabel(TagCategory category, String languageCode) {
  switch (category) {
    case TagCategory.mood:
      switch (languageCode) {
        case 'ja':
          return 'シーン';
        case 'ko':
          return '분위기';
        default:
          return 'Mood';
      }
    case TagCategory.price:
      switch (languageCode) {
        case 'ja':
          return '価格';
        case 'ko':
          return '가격';
        default:
          return 'Price';
      }
  }
}
