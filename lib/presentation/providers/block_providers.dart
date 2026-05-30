import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_block_repository.dart';
import '../../domain/entities/block_entity.dart';
import '../../domain/repositories/block_repository.dart';
import 'auth_providers.dart';

final blockRepositoryProvider = Provider<BlockRepository>((ref) {
  return FirebaseBlockRepository();
});

/// Live set of author ids the current user has blocked — the single source of
/// truth for hiding blocked authors' reviews. Empty set when signed out.
///
/// A stream, so the feed updates the moment a block/unblock lands without any
/// manual invalidation.
final blockedUserIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const <String>{});
  return ref.watch(blockRepositoryProvider).watchBlockedUserIds(user.uid);
});

/// Live list of the current user's blocks, newest-first — drives the
/// Blocked-users management screen. Empty when signed out.
final blockedUsersProvider = StreamProvider<List<BlockEntity>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const <BlockEntity>[]);
  return ref.watch(blockRepositoryProvider).watchBlocks(user.uid);
});

final blockControllerProvider = Provider<BlockController>((ref) {
  return BlockController(ref);
});

/// Thin action layer over [BlockRepository] (use-case role): resolves the
/// current uid, guards self-block, and writes through the repository. The
/// stream providers above pick up the change reactively.
class BlockController {
  BlockController(this._ref);

  final Ref _ref;

  /// Block a review author. No-op if signed out or if the target is the
  /// current user (defensive — own reviews never reach this path).
  Future<void> block({
    required String blockedUserId,
    required String blockedUserName,
    String? blockedUserPhotoUrl,
  }) async {
    final uid = _ref.read(currentUserProvider)?.uid;
    if (uid == null || uid == blockedUserId) return;
    await _ref
        .read(blockRepositoryProvider)
        .blockUser(
          blockerUserId: uid,
          blockedUserId: blockedUserId,
          blockedUserName: blockedUserName,
          blockedUserPhotoUrl: blockedUserPhotoUrl,
        );
  }

  /// Remove a block.
  Future<void> unblock(String blockedUserId) async {
    final uid = _ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    await _ref
        .read(blockRepositoryProvider)
        .unblockUser(blockerUserId: uid, blockedUserId: blockedUserId);
  }
}
