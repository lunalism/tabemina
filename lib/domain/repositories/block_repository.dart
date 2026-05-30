import '../entities/block_entity.dart';

/// Abstract block-storage contract.
///
/// Stage 0: client-only, no Cloud Functions. Blocking is one-directional and
/// private to the blocker. The presentation layer talks to this interface
/// only — never to Firestore directly.
abstract class BlockRepository {
  /// Block [blockedUserId] on behalf of [blockerUserId]. Idempotent — the
  /// doc id is deterministic (`{blocker}_{blocked}`), so re-blocking just
  /// overwrites the same doc. The name/photo are denormalized snapshots for
  /// the Blocked-users list.
  Future<void> blockUser({
    required String blockerUserId,
    required String blockedUserId,
    required String blockedUserName,
    String? blockedUserPhotoUrl,
  });

  /// Remove the block doc `{blockerUserId}_{blockedUserId}`.
  Future<void> unblockUser({
    required String blockerUserId,
    required String blockedUserId,
  });

  /// Live set of user ids [blockerUserId] has blocked — the single source of
  /// truth for hiding their reviews. Empty when there are none.
  Stream<Set<String>> watchBlockedUserIds(String blockerUserId);

  /// Live list of [blockerUserId]'s blocks, newest-first, for the management
  /// screen.
  Stream<List<BlockEntity>> watchBlocks(String blockerUserId);
}
