import '../entities/user_entity.dart';

/// Abstract user-profile-storage contract. Profiles live in `users/{uid}` so
/// reviews can read display name + avatar without a follow-up auth call.
abstract class UserRepository {
  /// Idempotent — call after every successful sign-in. Sets `createdAt` on
  /// first write and refreshes `updatedAt` on every call.
  Future<void> createOrUpdateUser(UserEntity user);

  Future<UserEntity?> getUser(String uid);

  Stream<UserEntity?> watchUser(String uid);

  /// Mark the account for deletion (App Store Guideline 5.1.1(v)). Stamps
  /// `pendingDeletionAt` with server time; the server finalizes 30 days later
  /// (B-2-4-2). Client-side only — does not delete any data here.
  Future<void> requestAccountDeletion(String uid);

  /// Cancel a pending deletion by clearing `pendingDeletionAt`. Called on
  /// recovery-by-login within the grace window.
  Future<void> cancelAccountDeletion(String uid);

  /// The pending-deletion timestamp, or `null` if no deletion is scheduled.
  Future<DateTime?> getPendingDeletionAt(String uid);
}
