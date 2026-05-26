import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/bookmark_entity.dart';
import '../../domain/repositories/bookmark_repository.dart';

/// Cloud-Firestore-backed [BookmarkRepository].
///
/// Bookmarks live under `users/{uid}/bookmarks/{placeId}` so the security
/// rule is trivially "uid-matches" and bookmarks can't leak across users.
/// Tying [BookmarkRepository.clearAll] to no-op here is deliberate — the
/// migration flow only clears local storage, never the cloud copy.
class FirebaseBookmarkRepository implements BookmarkRepository {
  FirebaseBookmarkRepository({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('users').doc(uid).collection('bookmarks');

  @override
  Future<void> addBookmark(BookmarkEntity bookmark) async {
    await _col.doc(bookmark.placeId).set(_toData(bookmark));
  }

  @override
  Future<void> removeBookmark(String placeId) async {
    await _col.doc(placeId).delete();
  }

  @override
  Future<List<BookmarkEntity>> getBookmarks() async {
    final snap = await _col.orderBy('savedAt', descending: true).get();
    return snap.docs.map((d) => _fromData(d.data())).toList();
  }

  @override
  Stream<List<BookmarkEntity>> watchBookmarks() {
    return _col.orderBy('savedAt', descending: true).snapshots().map(
          (s) => s.docs.map((d) => _fromData(d.data())).toList(),
        );
  }

  @override
  Future<bool> isBookmarked(String placeId) async {
    final doc = await _col.doc(placeId).get();
    return doc.exists;
  }

  @override
  Future<void> clearAll() async {
    // Intentional no-op — see class doc.
  }

  Map<String, dynamic> _toData(BookmarkEntity b) => {
        'placeId': b.placeId,
        'placeName': b.placeName,
        'placeAddress': b.placeAddress,
        'placeLat': b.placeLat,
        'placeLng': b.placeLng,
        'placePhotoUrl': b.placePhotoUrl,
        'placeRating': b.placeRating,
        'userRatingCount': b.userRatingCount,
        'priceLevel': b.priceLevel,
        'primaryType': b.primaryType,
        'savedAt': Timestamp.fromDate(b.savedAt),
      };

  BookmarkEntity _fromData(Map<String, dynamic> d) {
    return BookmarkEntity(
      placeId: d['placeId'] as String? ?? '',
      placeName: d['placeName'] as String? ?? '',
      placeAddress: d['placeAddress'] as String?,
      placeLat: (d['placeLat'] as num?)?.toDouble(),
      placeLng: (d['placeLng'] as num?)?.toDouble(),
      placePhotoUrl: d['placePhotoUrl'] as String?,
      placeRating: (d['placeRating'] as num?)?.toDouble(),
      userRatingCount: (d['userRatingCount'] as num?)?.toInt(),
      priceLevel: d['priceLevel'] as String?,
      primaryType: d['primaryType'] as String?,
      savedAt: _ts(d['savedAt']),
    );
  }

  DateTime _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return DateTime.now();
  }
}
