import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase-backed [AuthRepository].
///
/// All Firebase / Google / Apple imports are contained in this file by
/// design — the domain and presentation layers stay provider-agnostic.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Future<UserEntity?> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;

    final googleAuth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final result = await _auth.signInWithCredential(credential);
    return _mapUser(result.user);
  }

  @override
  Future<UserEntity?> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256(rawNonce);

    final AuthorizationCredentialAppleID appleCredential;
    try {
      appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }

    // Firebase verifies the Apple ID token against the SHA-256 hash of
    // rawNonce, which is why the raw value (not the hash) is what goes
    // into the OAuthCredential. authorizationCode is required as
    // accessToken — without it Firebase reports "Invalid OAuth response
    // from apple.com".
    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    final result = await _auth.signInWithCredential(oauthCredential);
    final user = result.user;

    // Apple only hands the name back on the FIRST sign-in. Persist it onto
    // the Firebase profile so subsequent loads have a non-null displayName.
    final stitched = _stitchAppleName(appleCredential);
    if (user != null && stitched != null && (user.displayName ?? '').isEmpty) {
      await user.updateDisplayName(stitched);
      await user.reload();
      return _mapUser(_auth.currentUser);
    }
    return _mapUser(user);
  }

  @override
  Future<void> signOut() async {
    // Sign out both Firebase and the Google session — without the Google
    // session signOut, the next signInWithGoogle() silently re-uses the
    // last picked account instead of showing the picker. We don't care if
    // the Google session is already gone, so swallow its errors.
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  @override
  UserEntity? getCurrentUser() => _mapUser(_auth.currentUser);

  @override
  Stream<UserEntity?> authStateChanges() =>
      _auth.authStateChanges().map(_mapUser);

  UserEntity? _mapUser(User? user) {
    if (user == null) return null;
    return UserEntity(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime,
    );
  }

  String? _stitchAppleName(AuthorizationCredentialAppleID c) {
    final parts = [c.givenName, c.familyName]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  /// Cryptographically-random nonce used to bind the Apple ID token to this
  /// sign-in request. Apple wants the SHA-256 hash; Firebase needs the raw
  /// value alongside the token to verify the binding.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();
}
