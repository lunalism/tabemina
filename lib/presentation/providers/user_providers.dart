import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_user_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import 'auth_providers.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirebaseUserRepository();
});

/// Side-effect provider that mirrors the signed-in [UserEntity] into the
/// `users/{uid}` document. Listen to it once in the root widget so every
/// sign-in stamps `createdAt` (first time) and `updatedAt` (every time).
final userProfileSyncProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;
  // Fire and forget — failures here are non-fatal (offline write, transient
  // permission error). The user still has a valid auth session; we'll
  // retry the next time they re-open the app.
  ref.read(userRepositoryProvider).createOrUpdateUser(user);
});

/// Snapshot read of the current user's Firestore profile (display name +
/// avatar). Falls back to the auth-derived entity if the doc hasn't been
/// written yet.
final currentUserProfileProvider = FutureProvider<UserEntity?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final profile = await ref.read(userRepositoryProvider).getUser(user.uid);
  return profile ?? user;
});
