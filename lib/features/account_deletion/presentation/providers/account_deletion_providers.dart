import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../presentation/providers/auth_providers.dart';
import '../../../../presentation/providers/review_providers.dart';
import '../../../../presentation/providers/user_providers.dart';

/// Result of evaluating a user's deletion state at sign-in.
enum DeletionRecoveryOutcome {
  /// No deletion was scheduled — normal sign-in.
  none,

  /// A pending deletion within the grace window was cancelled (recovered).
  cancelled,

  /// The grace window already elapsed — treat the account as gone (safety net;
  /// the server normally finalizes before this).
  expired,
}

/// Client-side orchestration for account deletion (App Store Guideline
/// 5.1.1(v)). This step only sets/clears `pendingDeletionAt` and drives the
/// UX — finalization (anonymizing reviews, deleting data, revoking tokens) is
/// the server's job in B-2-4-2.
class AccountDeletionController {
  AccountDeletionController(this._ref);

  final Ref _ref;

  /// Recovery window. After this elapses the server finalizes the deletion.
  static const Duration gracePeriod = Duration(days: 30);

  /// Request deletion for the signed-in user: stamp `pendingDeletionAt` and
  /// drop the per-account draft. The owner-write must run while still
  /// authenticated, so sign-out is deliberately NOT done here — the caller
  /// signs out only after it has navigated away to a public route (otherwise
  /// the auth flip races the router and re-shows the auth-gated screen).
  ///
  /// Reviews are left untouched — they stay visible through the grace period
  /// and are only anonymized at finalization (B-2-4-2).
  Future<void> requestDeletion() async {
    final uid = _ref.read(currentUserProvider)?.uid;
    if (uid == null) return;
    await _ref.read(userRepositoryProvider).requestAccountDeletion(uid);
    // Mirror the sign-out cleanup so a draft doesn't bleed into the next user.
    await _ref.read(draftStorageServiceProvider).clearDraft();
    _ref.invalidate(hasDraftProvider);
  }

  /// Evaluate a just-signed-in user's deletion state and act on it:
  /// within the grace window → clear the flag (recover); past it → report
  /// expired so the caller can sign the user back out.
  Future<DeletionRecoveryOutcome> handleSignInRecovery(String uid) async {
    final repo = _ref.read(userRepositoryProvider);
    final pendingAt = await repo.getPendingDeletionAt(uid);
    if (pendingAt == null) return DeletionRecoveryOutcome.none;
    if (DateTime.now().difference(pendingAt) < gracePeriod) {
      await repo.cancelAccountDeletion(uid);
      return DeletionRecoveryOutcome.cancelled;
    }
    return DeletionRecoveryOutcome.expired;
  }
}

final accountDeletionControllerProvider = Provider<AccountDeletionController>(
  (ref) => AccountDeletionController(ref),
);
