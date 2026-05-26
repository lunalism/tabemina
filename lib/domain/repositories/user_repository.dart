import '../entities/user_entity.dart';

/// Abstract user-profile-storage contract. Profiles live in `users/{uid}` so
/// reviews can read display name + avatar without a follow-up auth call.
abstract class UserRepository {
  /// Idempotent — call after every successful sign-in. Sets `createdAt` on
  /// first write and refreshes `updatedAt` on every call.
  Future<void> createOrUpdateUser(UserEntity user);

  Future<UserEntity?> getUser(String uid);

  Stream<UserEntity?> watchUser(String uid);
}
