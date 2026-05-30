import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/block_entity.dart';
import '../../domain/repositories/block_repository.dart';

/// Firestore implementation of [BlockRepository].
///
/// Blocks live in a top-level `blocks` collection keyed by a deterministic
/// `{blockerUid}_{blockedUid}` doc id (same dedup pattern as reports), so a
/// re-block is an idempotent `set()` — no pre-read needed. Security rules
/// keep each block private to its blocker.
class FirebaseBlockRepository implements BlockRepository {
  FirebaseBlockRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _blocks =>
      _firestore.collection('blocks');

  String _docId(String blockerUserId, String blockedUserId) =>
      '${blockerUserId}_$blockedUserId';

  @override
  Future<void> blockUser({
    required String blockerUserId,
    required String blockedUserId,
    required String blockedUserName,
    String? blockedUserPhotoUrl,
  }) async {
    await _blocks.doc(_docId(blockerUserId, blockedUserId)).set({
      'blockerUserId': blockerUserId,
      'blockedUserId': blockedUserId,
      'blockedUserName': blockedUserName,
      'blockedUserPhotoUrl': blockedUserPhotoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unblockUser({
    required String blockerUserId,
    required String blockedUserId,
  }) async {
    await _blocks.doc(_docId(blockerUserId, blockedUserId)).delete();
  }

  @override
  Stream<Set<String>> watchBlockedUserIds(String blockerUserId) {
    return _blocks
        .where('blockerUserId', isEqualTo: blockerUserId)
        .snapshots()
        .map(
          (snap) => {
            for (final d in snap.docs)
              if (d.data()['blockedUserId'] is String)
                d.data()['blockedUserId'] as String,
          },
        );
  }

  @override
  Stream<List<BlockEntity>> watchBlocks(String blockerUserId) {
    // Order client-side rather than via orderBy('createdAt') so a freshly
    // created block (serverTimestamp still null on the local echo) isn't
    // dropped from the query, and to avoid needing a composite index.
    return _blocks
        .where('blockerUserId', isEqualTo: blockerUserId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => _fromDoc(d.data())).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  BlockEntity _fromDoc(Map<String, dynamic> data) {
    final ts = data['createdAt'];
    return BlockEntity(
      blockerUserId: data['blockerUserId'] as String? ?? '',
      blockedUserId: data['blockedUserId'] as String? ?? '',
      blockedUserName: data['blockedUserName'] as String? ?? '',
      blockedUserPhotoUrl: data['blockedUserPhotoUrl'] as String?,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
