import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
    FirebaseFunctions? functions,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFunctions _functions;

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
    return _mapUser(
      result.user,
      isNewUser: result.additionalUserInfo?.isNewUser,
    );
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
    final isNewUser = result.additionalUserInfo?.isNewUser;

    // Capture the Apple refresh token server-side so account deletion can
    // revoke the app's Apple tokens (B-2-4-2b, required by Apple). The
    // authorizationCode is single-use and only available here, right after the
    // native authorization. Fire-and-forget + fail-soft: this must never block
    // or fail sign-in.
    if (user != null && appleCredential.authorizationCode.isNotEmpty) {
      unawaited(_registerAppleRefreshToken(appleCredential.authorizationCode));
    }

    // Apple only hands the name back on the FIRST sign-in. Persist it onto
    // the Firebase profile so subsequent loads have a non-null displayName.
    final stitched = _stitchAppleName(appleCredential);
    if (user != null && stitched != null && (user.displayName ?? '').isEmpty) {
      await user.updateDisplayName(stitched);
      await user.reload();
      return _mapUser(_auth.currentUser, isNewUser: isNewUser);
    }
    return _mapUser(user, isNewUser: isNewUser);
  }

  /// Hand the one-time Apple authorization code to the backend, which
  /// exchanges it for a refresh token and stores it for later revocation.
  /// Fails soft — a backend/network error is logged and swallowed so it can
  /// never break the sign-in flow. The code/token never touch the client.
  Future<void> _registerAppleRefreshToken(String authorizationCode) async {
    try {
      await _functions
          .httpsCallable('registerAppleRefreshToken')
          .call<void>({'authorizationCode': authorizationCode});
    } catch (e) {
      // Non-fatal: without the stored refresh token, deletion simply can't
      // revoke this user's Apple tokens (also logged server-side).
      debugPrint('registerAppleRefreshToken failed: $e');
    }
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

  UserEntity? _mapUser(User? user, {bool? isNewUser}) {
    if (user == null) return null;
    return UserEntity(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime,
      isNewUser: isNewUser,
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
