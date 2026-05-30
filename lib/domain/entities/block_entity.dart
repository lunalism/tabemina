import 'package:flutter/foundation.dart';

/// A one-directional block: [blockerUserId] no longer sees reviews authored by
/// [blockedUserId]. The blocked user is unaffected and never notified.
///
/// [blockedUserName] / [blockedUserPhotoUrl] are denormalized snapshots taken
/// at block time so the Blocked-users list renders without N profile reads —
/// staleness is acceptable for stage 0. Mirrors the Firestore
/// `blocks/{blockerUid}_{blockedUid}` document.
@immutable
class BlockEntity {
  const BlockEntity({
    required this.blockerUserId,
    required this.blockedUserId,
    required this.blockedUserName,
    required this.createdAt,
    this.blockedUserPhotoUrl,
  });

  final String blockerUserId;
  final String blockedUserId;
  final String blockedUserName;
  final String? blockedUserPhotoUrl;
  final DateTime createdAt;
}
