import '../../../core/constants/legal_constants.dart';
import '../domain/eula_repository.dart';
import 'datasources/eula_local_data_source.dart';
import 'datasources/eula_remote_data_source.dart';

/// Coordinates the local cache and remote record behind [EulaRepository].
///
/// "Has consented" = a stored accepted version (local *or* remote) that equals
/// the current [LegalConstants.eulaVersion].
class EulaRepositoryImpl implements EulaRepository {
  EulaRepositoryImpl({required this._local, required this._remote});

  final EulaLocalDataSource _local;
  final EulaRemoteDataSource _remote;

  @override
  Future<bool> hasAcceptedCurrentVersion(String uid) async {
    // Local cache first — the common path, no network.
    if (_local.getAcceptedVersion() == LegalConstants.eulaVersion) {
      return true;
    }
    // Fall back to the remote record; warm the cache on a hit so future
    // launches skip the read.
    final remoteVersion = await _remote.getAcceptedVersion(uid);
    if (remoteVersion == LegalConstants.eulaVersion) {
      await _local.setAcceptedVersion(remoteVersion!);
      return true;
    }
    return false;
  }

  @override
  Future<void> acceptCurrentVersion(String uid) async {
    // Remote first so the durable record exists before we trust the cache; a
    // write failure then surfaces to the caller instead of being masked by a
    // "true" local flag.
    await _remote.setAcceptedVersion(uid, LegalConstants.eulaVersion);
    await _local.setAcceptedVersion(LegalConstants.eulaVersion);
  }

  @override
  Future<void> clearLocalCache() => _local.clear();
}
