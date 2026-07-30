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

  /// Separate key for the in-flight submit's stable review id. Deliberately NOT
  /// part of [_draftKey]: the draft holds the user's CONTENT and is cleared when
  /// they discard it, whereas the id is an IDEMPOTENCY TOKEN. Clearing the two
  /// together meant discarding the draft while a write was still queued dropped
  /// the token, so the next Post minted a fresh document id and published a
  /// second review once the queued write landed.
  static const _pendingIdKey = 'review_pending_id';

  /// How long a stored pending id stays adoptable.
  ///
  /// Matches the 24h per-place review cooldown, and that alignment is the point:
  /// INSIDE the window a second review for the same place is blocked anyway, so
  /// adopting the id can only prevent a duplicate. OUTSIDE it, a new review is
  /// legitimate — and adopting a stale id there would be actively harmful, since
  /// [ReviewRepository.probeReviewWrite] would find the old committed document,
  /// report success, and silently discard what the user just wrote.
  static const _pendingIdMaxAge = Duration(hours: 24);

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

  // ---- Pending submit ids ---------------------------------------------------
  //
  // Survives [clearDraft] on purpose. See [_pendingIdKey].
  //
  // Stored as a MAP keyed by placeId, not one global record. A single record
  // meant posting at place B silently overwrote place A's still-outstanding
  // token, so a later retry at A would mint a fresh id and A's queued write
  // could land alongside it as a duplicate. Unlike the draft — deliberately
  // single-slot, because the user only composes one review at a time — several
  // submits can be in flight at once, so their identities cannot share a slot.
  //
  // Each entry also carries the submitting userId. Without it, signing out and
  // signing in as someone else on the same device would let the second user
  // adopt the first user's token: the probe finds the first user's committed
  // document, reports success, and the second user's review is silently
  // discarded. Both sign-out paths additionally clear the whole map, matching
  // how they already clear the draft as per-account data.

  /// Remember the stable review id minted for [userId]'s submit against
  /// [placeId]. Expired entries are pruned on the way through so the map can't
  /// grow without bound.
  Future<void> savePendingReviewId({
    required String placeId,
    required String reviewId,
    required String userId,
  }) async {
    final map = _readPendingMap()..removeWhere((_, v) => _isExpired(v));
    map[placeId] = {
      'reviewId': reviewId,
      'userId': userId,
      'savedAt': DateTime.now().toIso8601String(),
    };
    await _prefs.setString(_pendingIdKey, jsonEncode(map));
  }

  /// The stored pending review id for [placeId], but only when it is safe to
  /// adopt: it must belong to [userId] and be younger than [_pendingIdMaxAge].
  ///
  /// Keying by placeId preserves the B-track scoping rule — a retained id must
  /// never be adopted for a different restaurant, which would re-target that
  /// restaurant's document. An expired or foreign-user entry is dropped as a side
  /// effect so it can't linger and be re-evaluated on every submit.
  Future<String?> loadPendingReviewId({
    required String placeId,
    required String userId,
  }) async {
    final map = _readPendingMap();
    final entry = map[placeId];
    if (entry == null) return null;

    final id = entry['reviewId'];
    final owner = entry['userId'];
    if (id is! String || id.isEmpty || owner != userId || _isExpired(entry)) {
      map.remove(placeId);
      await _prefs.setString(_pendingIdKey, jsonEncode(map));
      return null;
    }
    return id;
  }

  /// Drop [placeId]'s pending id. Correct ONLY once that write has been
  /// server-acked — see the call site in the write screen's success path. Other
  /// places' entries are left alone; their submits may still be outstanding.
  Future<void> clearPendingReviewId(String placeId) async {
    final map = _readPendingMap();
    if (map.remove(placeId) == null) return;
    await _prefs.setString(_pendingIdKey, jsonEncode(map));
  }

  /// Drop every pending id. For sign-out and account deletion, alongside the
  /// existing [clearDraft] — this is per-account data and must not bleed into
  /// the next user's session.
  Future<void> clearAllPendingReviewIds() async {
    await _prefs.remove(_pendingIdKey);
  }

  Map<String, Map<String, dynamic>> _readPendingMap() {
    final raw = _prefs.getString(_pendingIdKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final e in decoded.entries)
          if (e.key is String && e.value is Map)
            e.key as String: Map<String, dynamic>.from(e.value as Map),
      };
    } catch (_) {
      // Corrupt payload — treat as empty. Not cleared here: this is called from
      // read paths that must stay side-effect-free on the happy path, and the
      // next save overwrites it wholesale anyway.
      return {};
    }
  }

  bool _isExpired(Map<String, dynamic> entry) {
    final raw = entry['savedAt'];
    // Type-check rather than cast: `as String?` throws on any other non-null
    // type, and this runs on the normal submit path (both the load and the prune
    // inside savePendingReviewId), so a malformed value would surface as a failed
    // submit. Treated as expired instead — the same "corrupt payload means no
    // usable record" convention loadDraft follows. Dropping an undateable entry
    // risks a duplicate; adopting one risks silently discarding a review the user
    // just wrote, and the entry being undateable is exactly the case where we
    // cannot tell which.
    if (raw is! String) return true;
    final savedAt = DateTime.tryParse(raw);
    return savedAt == null ||
        DateTime.now().difference(savedAt) > _pendingIdMaxAge;
  }
}
