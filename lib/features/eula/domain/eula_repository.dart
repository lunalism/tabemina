/// Abstract EULA-consent storage contract.
///
/// Consent is the source of truth for the post-sign-in gate (App Store
/// Guideline 1.2). The presentation layer talks to this interface only; the
/// data layer coordinates a local cache (shared_preferences) and the remote
/// record (`users/{uid}`).
abstract class EulaRepository {
  /// Whether [uid] has accepted the *current* EULA version.
  ///
  /// Checks the local cache first to avoid a Firestore read on every launch,
  /// falling back to the remote record. A remote hit warms the local cache.
  Future<bool> hasAcceptedCurrentVersion(String uid);

  /// Record acceptance of the current EULA version for [uid] — writes the
  /// remote record (with a server timestamp) and warms the local cache.
  Future<void> acceptCurrentVersion(String uid);

  /// Drop the local cache. Called on sign-out / decline so a different account
  /// signing in on the same device is re-evaluated against its own record
  /// (the local key is device-global, not per-uid).
  Future<void> clearLocalCache();
}
