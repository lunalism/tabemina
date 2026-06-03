import 'package:cloud_firestore/cloud_firestore.dart';

/// Remote EULA-consent record, stored on the user's profile doc
/// (`users/{uid}`) alongside the fields written by the profile sync.
///
/// Uses `set(..., merge: true)` so stamping consent never clobbers other
/// profile fields, and works even if the profile doc hasn't been created yet
/// (first sign-in, where the fire-and-forget profile sync may not have landed).
class EulaRemoteDataSource {
  EulaRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// The accepted EULA version on record, or `null` if never accepted.
  Future<String?> getAcceptedVersion(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    return snap.data()?['eulaAcceptedVersion'] as String?;
  }

  /// Stamp [version] plus a server timestamp for when it was accepted.
  Future<void> setAcceptedVersion(String uid, String version) {
    return _doc(uid).set({
      'eulaAcceptedVersion': version,
      'eulaAcceptedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
