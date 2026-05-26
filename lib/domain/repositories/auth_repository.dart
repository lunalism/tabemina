import '../entities/user_entity.dart';

/// Abstract auth contract.
///
/// The presentation layer talks to this interface, never to FirebaseAuth.
/// Swapping the provider later (e.g. Supabase) only requires a new
/// implementation class in the data layer.
abstract class AuthRepository {
  /// Trigger the Google Sign-In flow and return the signed-in user.
  ///
  /// Returns `null` when the user cancels the picker — implementations must
  /// distinguish cancellation (return null) from real errors (throw).
  Future<UserEntity?> signInWithGoogle();

  /// Trigger the Apple Sign-In flow and return the signed-in user.
  ///
  /// Returns `null` when the user cancels. Throws on network or token errors.
  Future<UserEntity?> signInWithApple();

  Future<void> signOut();

  /// Synchronous read of the currently signed-in user, or `null` if guest.
  UserEntity? getCurrentUser();

  /// Stream of auth changes — emits the current user on subscribe and
  /// re-emits on every sign-in / sign-out.
  Stream<UserEntity?> authStateChanges();
}
