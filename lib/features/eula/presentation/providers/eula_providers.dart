import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_locale_provider.dart';
import '../../../../presentation/providers/auth_providers.dart';
import '../../data/datasources/eula_local_data_source.dart';
import '../../data/datasources/eula_remote_data_source.dart';
import '../../data/eula_repository_impl.dart';
import '../../domain/eula_repository.dart';

/// Outcome of evaluating EULA consent for the current auth state.
enum EulaConsentStatus {
  /// No authenticated user — guest browsing, the gate does not apply.
  notRequired,

  /// Authenticated and has accepted the current EULA version.
  accepted,

  /// Authenticated but has NOT accepted the current version — show the gate.
  gateRequired,
}

/// Concrete EULA store. Swap this provider's body to migrate off Firebase
/// without touching the gate UI.
final eulaRepositoryProvider = Provider<EulaRepository>((ref) {
  return EulaRepositoryImpl(
    local: EulaLocalDataSource(ref.read(sharedPreferencesProvider)),
    remote: EulaRemoteDataSource(),
  );
});

/// Reactive consent state, keyed off the authenticated user.
///
/// Rebuilds whenever auth changes: a fresh sign-in (or an existing signed-in
/// user who has never accepted / accepted an older version) resolves to
/// [EulaConsentStatus.gateRequired], which the router turns into a redirect to
/// the gate. Sign-out resolves back to [EulaConsentStatus.notRequired].
class EulaConsentNotifier extends AsyncNotifier<EulaConsentStatus> {
  @override
  Future<EulaConsentStatus> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return EulaConsentStatus.notRequired;
    final accepted = await ref
        .read(eulaRepositoryProvider)
        .hasAcceptedCurrentVersion(user.uid);
    return accepted
        ? EulaConsentStatus.accepted
        : EulaConsentStatus.gateRequired;
  }

  /// Record acceptance and flip to [EulaConsentStatus.accepted]. Throws if the
  /// remote write fails so the gate can keep the user there and let them retry.
  Future<void> accept() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref.read(eulaRepositoryProvider).acceptCurrentVersion(user.uid);
    state = const AsyncData(EulaConsentStatus.accepted);
  }

  /// Decline: clear the device-global cache and sign out. The auth change then
  /// rebuilds this provider to [EulaConsentStatus.notRequired], returning the
  /// user to guest browsing. No consent is stored.
  Future<void> decline() async {
    await ref.read(eulaRepositoryProvider).clearLocalCache();
    await ref.read(authRepositoryProvider).signOut();
  }
}

final eulaConsentProvider =
    AsyncNotifierProvider<EulaConsentNotifier, EulaConsentStatus>(
      EulaConsentNotifier.new,
    );
