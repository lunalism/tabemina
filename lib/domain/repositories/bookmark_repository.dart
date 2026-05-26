import '../entities/bookmark_entity.dart';

/// Abstract bookmark-storage contract.
///
/// Two implementations live in the data layer: a Firestore-backed one for
/// signed-in users and a SharedPreferences-backed one for guests. The
/// provider picks the right impl based on auth state.
abstract class BookmarkRepository {
  Future<void> addBookmark(BookmarkEntity bookmark);

  Future<void> removeBookmark(String placeId);

  Future<List<BookmarkEntity>> getBookmarks();

  Stream<List<BookmarkEntity>> watchBookmarks();

  Future<bool> isBookmarked(String placeId);

  /// Wipe local storage. Used after a successful guest→cloud migration so
  /// the same bookmark doesn't show twice (once from cache, once from
  /// Firestore) — only the local impl needs to do anything here; the cloud
  /// impl can no-op.
  Future<void> clearAll();
}
