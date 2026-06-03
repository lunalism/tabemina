import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';

/// Firestore-backed user profile store.
///
/// Uses `set(..., SetOptions(merge: true))` so re-running the sync after a
/// re-login never clobbers fields that were updated elsewhere (e.g. a
/// profile-photo refresh from Apple isn't allowed to wipe a Google-issued
/// avatar that's actually displayed).
class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid);

  @override
  Future<void> createOrUpdateUser(UserEntity user) async {
    final ref = _doc(user.uid);
    final existing = await ref.get();
    final data = <String, dynamic>{
      'uid': user.uid,
      'displayName': user.displayName,
      'email': user.email,
      'photoUrl': user.photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    // Only stamp createdAt on first write — repeat sign-ins shouldn't reset it.
    if (!existing.exists) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await ref.set(data, SetOptions(merge: true));
  }

  @override
  Future<UserEntity?> getUser(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    return _fromData(uid, snap.data()!);
  }

  @override
  Stream<UserEntity?> watchUser(String uid) {
    return _doc(uid).snapshots().map((s) {
      if (!s.exists) return null;
      return _fromData(uid, s.data()!);
    });
  }

  @override
  Future<void> requestAccountDeletion(String uid) {
    return _doc(uid).set({
      'pendingDeletionAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> cancelAccountDeletion(String uid) {
    // FieldValue.delete() removes the field entirely (not set to null), so the
    // account reads as "no deletion scheduled" again.
    return _doc(
      uid,
    ).set({'pendingDeletionAt': FieldValue.delete()}, SetOptions(merge: true));
  }

  @override
  Future<DateTime?> getPendingDeletionAt(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    return _ts(snap.data()?['pendingDeletionAt']);
  }

  UserEntity _fromData(String uid, Map<String, dynamic> d) {
    return UserEntity(
      uid: uid,
      displayName: d['displayName'] as String?,
      email: d['email'] as String?,
      photoUrl: d['photoUrl'] as String?,
      createdAt: _ts(d['createdAt']),
    );
  }

  DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }
}
