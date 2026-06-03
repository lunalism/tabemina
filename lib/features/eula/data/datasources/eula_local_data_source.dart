import 'package:shared_preferences/shared_preferences.dart';

/// Local (device-global) cache of the accepted EULA version.
///
/// A single key — not per-uid — so the common "same user reopens the app" path
/// short-circuits the Firestore read. Multi-account devices stay correct
/// because the cache is cleared on sign-out/decline and the remote record is
/// the fallback source of truth.
class EulaLocalDataSource {
  EulaLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const String _key = 'eula_accepted_version';

  String? getAcceptedVersion() => _prefs.getString(_key);

  Future<void> setAcceptedVersion(String version) =>
      _prefs.setString(_key, version);

  Future<void> clear() => _prefs.remove(_key);
}
