/// Snackbar / empty-state / dialog strings for the bookmarks flow.
///
/// Lives here (not in the provider file) so screen widgets can import it
/// without dragging the storage backend into their build dependencies.
class BookmarksLabels {
  const BookmarksLabels({
    required this.title,
    required this.empty,
    required this.emptyHint,
    required this.exploreNearby,
    required this.savedSnack,
    required this.removedSnack,
    required this.removeConfirmTitle,
    required this.removeConfirmBody,
    required this.removeYes,
    required this.removeNo,
    required this.justNow,
    required this.minutesAgo,
    required this.hoursAgo,
    required this.daysAgo,
    required this.weeksAgo,
    required this.monthsAgo,
    required this.yearsAgo,
    required this.savedPrefix,
  });

  final String title;
  final String empty;
  final String emptyHint;
  final String exploreNearby;
  final String savedSnack;
  final String removedSnack;
  final String removeConfirmTitle;
  final String removeConfirmBody;
  final String removeYes;
  final String removeNo;
  final String Function(int n) justNow;
  final String Function(int n) minutesAgo;
  final String Function(int n) hoursAgo;
  final String Function(int n) daysAgo;
  final String Function(int n) weeksAgo;
  final String Function(int n) monthsAgo;
  final String Function(int n) yearsAgo;
  final String savedPrefix;

  static BookmarksLabels of(String languageCode) {
    switch (languageCode) {
      case 'ja':
        return BookmarksLabels(
          title: 'ブックマーク',
          empty: 'まだブックマークがありません',
          emptyHint: 'レストランの保存アイコンをタップしてブックマークしましょう',
          exploreNearby: '近くを探す',
          savedSnack: 'ブックマークに保存しました',
          removedSnack: 'ブックマークから削除しました',
          removeConfirmTitle: 'ブックマークから削除しますか?',
          removeConfirmBody: 'このお店をブックマークから削除します。',
          removeYes: '削除',
          removeNo: 'キャンセル',
          justNow: (_) => 'たった今',
          minutesAgo: (n) => '$n分前',
          hoursAgo: (n) => '$n時間前',
          daysAgo: (n) => '$n日前',
          weeksAgo: (n) => '$n週間前',
          monthsAgo: (n) => '$nヶ月前',
          yearsAgo: (n) => '$n年前',
          savedPrefix: '保存',
        );
      case 'ko':
        return BookmarksLabels(
          title: '북마크',
          empty: '아직 북마크가 없습니다',
          emptyHint: '식당의 저장 아이콘을 탭하여 북마크하세요',
          exploreNearby: '근처 탐색',
          savedSnack: '북마크에 저장했습니다',
          removedSnack: '북마크에서 삭제했습니다',
          removeConfirmTitle: '북마크에서 삭제할까요?',
          removeConfirmBody: '이 식당을 북마크에서 제거합니다.',
          removeYes: '삭제',
          removeNo: '취소',
          justNow: (_) => '방금 전',
          minutesAgo: (n) => '$n분 전',
          hoursAgo: (n) => '$n시간 전',
          daysAgo: (n) => '$n일 전',
          weeksAgo: (n) => '$n주 전',
          monthsAgo: (n) => '$n개월 전',
          yearsAgo: (n) => '$n년 전',
          savedPrefix: '저장',
        );
      case 'en':
      default:
        return BookmarksLabels(
          title: 'Bookmarks',
          empty: 'No bookmarks yet',
          emptyHint: 'Tap the save icon on any restaurant to bookmark it',
          exploreNearby: 'Explore nearby',
          savedSnack: 'Saved to bookmarks',
          removedSnack: 'Removed from bookmarks',
          removeConfirmTitle: 'Remove from bookmarks?',
          removeConfirmBody:
              'This restaurant will be removed from your bookmarks.',
          removeYes: 'Remove',
          removeNo: 'Cancel',
          justNow: (_) => 'just now',
          minutesAgo: (n) => '${n}m ago',
          hoursAgo: (n) => '${n}h ago',
          daysAgo: (n) => '${n}d ago',
          weeksAgo: (n) => '${n}w ago',
          monthsAgo: (n) => '${n}mo ago',
          yearsAgo: (n) => '${n}y ago',
          savedPrefix: 'Saved',
        );
    }
  }
}

/// Render the saved-at timestamp as a short relative string.
String formatRelativeSaved(DateTime savedAt, BookmarksLabels l) {
  final diff = DateTime.now().difference(savedAt);
  if (diff.inSeconds < 60) return l.justNow(diff.inSeconds);
  if (diff.inMinutes < 60) return l.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l.hoursAgo(diff.inHours);
  if (diff.inDays < 7) return l.daysAgo(diff.inDays);
  if (diff.inDays < 30) return l.weeksAgo(diff.inDays ~/ 7);
  if (diff.inDays < 365) return l.monthsAgo(diff.inDays ~/ 30);
  return l.yearsAgo(diff.inDays ~/ 365);
}
