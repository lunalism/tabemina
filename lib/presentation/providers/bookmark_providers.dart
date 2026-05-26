import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_locale_provider.dart';
import '../../data/repositories/firebase_bookmark_repository.dart';
import '../../data/repositories/local_bookmark_repository.dart';
import '../../domain/entities/bookmark_entity.dart';
import '../../domain/repositories/bookmark_repository.dart';
import 'auth_providers.dart';

/// Local-only repo, always available. Used for guests, and as the source
/// during the one-time guest→cloud migration when a user signs in.
final localBookmarkRepositoryProvider = Provider<LocalBookmarkRepository>((ref) {
  return LocalBookmarkRepository(ref.watch(sharedPreferencesProvider));
});

/// Active repo: Firestore-backed when signed in, SharedPreferences-backed
/// when guest. Watchers re-resolve automatically when auth state flips, so
/// the bookmarks tab redraws against the right source on sign-in / sign-out.
final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    return FirebaseBookmarkRepository(uid: user.uid);
  }
  return ref.watch(localBookmarkRepositoryProvider);
});

/// All bookmarks for the current session — newest-first. Lives as a stream
/// so a save from the detail screen reflects in the Bookmarks tab without
/// a manual refresh.
final bookmarksProvider = StreamProvider<List<BookmarkEntity>>((ref) {
  return ref.watch(bookmarkRepositoryProvider).watchBookmarks();
});

/// Cheap reactive check for "is this place currently bookmarked?". Derived
/// off [bookmarksProvider] so the heart toggles instantly without an extra
/// Firestore read per detail screen.
final isBookmarkedProvider = Provider.family<bool, String>((ref, placeId) {
  return ref.watch(bookmarksProvider).maybeWhen(
        data: (list) => list.any((b) => b.placeId == placeId),
        orElse: () => false,
      );
});

/// One-time guest→cloud migration: when a user signs in, copy any local
/// bookmarks into their Firestore subcollection and clear the local store.
///
/// Wired up via [bookmarkMigrationProvider] as a side-effect provider on
/// app start. Idempotent — once the local store is empty, subsequent
/// invocations are no-ops, so it's safe to listen even on every rebuild.
final bookmarkMigrationProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;
  final local = ref.read(localBookmarkRepositoryProvider);
  // Async hop without await — providers can't be async. The migration runs
  // in the background and self-clears once done.
  Future.microtask(() async {
    final pending = await local.getBookmarks();
    if (pending.isEmpty) return;
    final cloud = FirebaseBookmarkRepository(uid: user.uid);
    for (final b in pending) {
      await cloud.addBookmark(b);
    }
    await local.clearAll();
  });
});
