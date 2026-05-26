import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// The concrete auth implementation. Swap this provider's body to migrate
/// off Firebase without touching any UI code.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Live auth state — re-emits whenever Firebase reports a sign-in or
/// sign-out. The UI watches this to flip between guest and signed-in
/// affordances.
final authStateProvider = StreamProvider<UserEntity?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

/// Synchronous current-user view derived from [authStateProvider]. Returns
/// `null` while the stream is loading (treat-as-guest) and on sign-out.
final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authStateProvider).maybeWhen(
        data: (user) => user,
        orElse: () => null,
      );
});
