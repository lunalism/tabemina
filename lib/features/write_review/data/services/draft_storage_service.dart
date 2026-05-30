import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/review_draft.dart';

/// Persists a single in-progress NEW review to SharedPreferences as JSON.
///
/// Only ONE draft exists at a time — saving overwrites the previous one.
/// Drafts are for create-mode only; edit mode never touches this service.
/// The whole draft is stored under one key, mirroring
/// `LocalBookmarkRepository`'s single-key JSON approach.
class DraftStorageService {
  DraftStorageService(this._prefs);

  static const _draftKey = 'review_draft';

  final SharedPreferences _prefs;

  /// Save [draft], replacing any existing one.
  Future<void> saveDraft(ReviewDraft draft) async {
    await _prefs.setString(_draftKey, jsonEncode(draft.toJson()));
  }

  /// Load the stored draft, or null if none / unparseable.
  Future<ReviewDraft?> loadDraft() async {
    final raw = _prefs.getString(_draftKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return ReviewDraft.fromJson(decoded);
    } catch (_) {
      // Corrupt payload — treat as no draft and clear it so we don't keep
      // tripping on it.
      await clearDraft();
      return null;
    }
  }

  /// Delete the stored draft (after submission, manual discard, or logout).
  Future<void> clearDraft() async {
    await _prefs.remove(_draftKey);
  }

  /// Whether a draft is currently stored.
  Future<bool> hasDraft() async {
    final raw = _prefs.getString(_draftKey);
    return raw != null && raw.isNotEmpty;
  }
}
