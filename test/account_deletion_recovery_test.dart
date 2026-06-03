import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabemina/domain/entities/user_entity.dart';
import 'package:tabemina/domain/repositories/user_repository.dart';
import 'package:tabemina/features/account_deletion/presentation/providers/account_deletion_providers.dart';
import 'package:tabemina/presentation/providers/user_providers.dart';

/// In-memory UserRepository so the recovery grace-window decision can be tested
/// without Firestore.
class _FakeUserRepository implements UserRepository {
  _FakeUserRepository(this.pendingAt);

  DateTime? pendingAt;
  bool cancelCalled = false;

  @override
  Future<DateTime?> getPendingDeletionAt(String uid) async => pendingAt;

  @override
  Future<void> cancelAccountDeletion(String uid) async {
    cancelCalled = true;
    pendingAt = null;
  }

  @override
  Future<void> requestAccountDeletion(String uid) async =>
      pendingAt = DateTime.now();

  @override
  Future<void> createOrUpdateUser(UserEntity user) async {}

  @override
  Future<UserEntity?> getUser(String uid) async => null;

  @override
  Stream<UserEntity?> watchUser(String uid) => const Stream.empty();
}

void main() {
  ProviderContainer containerWith(_FakeUserRepository repo) {
    final c = ProviderContainer(
      overrides: [userRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('no pending deletion -> none, nothing cleared', () async {
    final repo = _FakeUserRepository(null);
    final outcome = await containerWith(repo)
        .read(accountDeletionControllerProvider)
        .handleSignInRecovery('uid');
    expect(outcome, DeletionRecoveryOutcome.none);
    expect(repo.cancelCalled, isFalse);
  });

  test('within 30-day grace -> cancelled and flag cleared', () async {
    final repo = _FakeUserRepository(
      DateTime.now().subtract(const Duration(days: 10)),
    );
    final outcome = await containerWith(repo)
        .read(accountDeletionControllerProvider)
        .handleSignInRecovery('uid');
    expect(outcome, DeletionRecoveryOutcome.cancelled);
    expect(repo.cancelCalled, isTrue);
    expect(repo.pendingAt, isNull);
  });

  test('past 30-day grace -> expired, flag NOT cleared', () async {
    final repo = _FakeUserRepository(
      DateTime.now().subtract(const Duration(days: 31)),
    );
    final outcome = await containerWith(repo)
        .read(accountDeletionControllerProvider)
        .handleSignInRecovery('uid');
    expect(outcome, DeletionRecoveryOutcome.expired);
    expect(repo.cancelCalled, isFalse);
  });
}
