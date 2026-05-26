import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/bookmark_entity.dart';
import '../../domain/repositories/bookmark_repository.dart';

/// SharedPreferences-backed [BookmarkRepository] for guest users.
///
/// Stores the whole list as a JSON array under one key — small dataset, no
/// query needs, and the read happens synchronously off the awaited prefs
/// instance so the bookmarks tab paints on the first frame.
///
/// A broadcast [StreamController] re-emits the list on every mutation so
/// [watchBookmarks] mirrors the Firestore-backed impl's reactive shape.
class LocalBookmarkRepository implements BookmarkRepository {
  LocalBookmarkRepository(this._prefs);

  static const _prefsKey = 'bookmarked_restaurants';

  final SharedPreferences _prefs;
  final StreamController<List<BookmarkEntity>> _controller =
      StreamController.broadcast();

  List<BookmarkEntity> _read() {
    final raw = _prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List;
      final list = decoded
          .whereType<Map<String, dynamic>>()
          .map(_fromJson)
          .toList();
      list.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return list;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _write(List<BookmarkEntity> list) async {
    final encoded =
        jsonEncode(list.map(_toJson).toList(growable: false));
    await _prefs.setString(_prefsKey, encoded);
    _controller.add(list);
  }

  @override
  Future<void> addBookmark(BookmarkEntity bookmark) async {
    final current = _read();
    final next = [
      bookmark,
      ...current.where((b) => b.placeId != bookmark.placeId),
    ];
    await _write(next);
  }

  @override
  Future<void> removeBookmark(String placeId) async {
    final current = _read();
    final next = current.where((b) => b.placeId != placeId).toList();
    if (next.length == current.length) return;
    await _write(next);
  }

  @override
  Future<List<BookmarkEntity>> getBookmarks() async => _read();

  @override
  Stream<List<BookmarkEntity>> watchBookmarks() async* {
    yield _read();
    yield* _controller.stream;
  }

  @override
  Future<bool> isBookmarked(String placeId) async {
    return _read().any((b) => b.placeId == placeId);
  }

  @override
  Future<void> clearAll() async {
    await _prefs.remove(_prefsKey);
    _controller.add(const []);
  }

  Map<String, dynamic> _toJson(BookmarkEntity b) => {
        'placeId': b.placeId,
        'placeName': b.placeName,
        if (b.placeAddress != null) 'placeAddress': b.placeAddress,
        if (b.placeLat != null) 'placeLat': b.placeLat,
        if (b.placeLng != null) 'placeLng': b.placeLng,
        if (b.placePhotoUrl != null) 'placePhotoUrl': b.placePhotoUrl,
        if (b.placeRating != null) 'placeRating': b.placeRating,
        if (b.userRatingCount != null) 'userRatingCount': b.userRatingCount,
        if (b.priceLevel != null) 'priceLevel': b.priceLevel,
        if (b.primaryType != null) 'primaryType': b.primaryType,
        'savedAt': b.savedAt.toIso8601String(),
      };

  BookmarkEntity _fromJson(Map<String, dynamic> json) {
    return BookmarkEntity(
      placeId: json['placeId'] as String? ?? '',
      placeName: (json['placeName'] ?? json['name']) as String? ?? '',
      placeAddress: (json['placeAddress'] ?? json['address']) as String?,
      placeLat: (json['placeLat'] as num?)?.toDouble(),
      placeLng: (json['placeLng'] as num?)?.toDouble(),
      placePhotoUrl:
          (json['placePhotoUrl'] ?? json['photoUrl']) as String?,
      placeRating:
          ((json['placeRating'] ?? json['rating']) as num?)?.toDouble(),
      userRatingCount: (json['userRatingCount'] as num?)?.toInt(),
      priceLevel: json['priceLevel'] as String?,
      primaryType: json['primaryType'] as String?,
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
