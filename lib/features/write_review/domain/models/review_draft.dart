/// Minimal context for a review's target restaurant.
///
/// Populated either from the Detail-screen entry point (we already have the
/// full place) or from the in-screen search step. Persisting just these
/// four fields means the draft can be saved without re-fetching the full
/// PlaceDetail.
class ReviewRestaurant {
  const ReviewRestaurant({
    required this.placeId,
    required this.name,
    this.primaryType,
    this.photoUrl,
  });

  final String placeId;
  final String name;
  final String? primaryType;
  final String? photoUrl;
}

/// A persisted, in-progress NEW review (never used for edit mode).
///
/// Saved to SharedPreferences as JSON so an unfinished review survives an
/// app close / tab switch. Photos are stored as LOCAL file paths of the
/// originally-picked images — not Firebase URLs — so a restored draft can
/// re-process and re-upload them. Paths whose files no longer exist on the
/// device are skipped silently on restore.
class ReviewDraft {
  const ReviewDraft({
    this.placeId,
    this.placeName,
    this.placePhotoUrl,
    this.placeType,
    this.rating,
    this.moodTags = const [],
    this.priceTag,
    this.comment,
    this.localPhotoPaths = const [],
    required this.savedAt,
  });

  /// Selected restaurant id (null until one is chosen).
  final String? placeId;

  /// Restaurant name, for the mini-card on restore.
  final String? placeName;

  /// Restaurant photo URL, for the mini-card on restore.
  final String? placePhotoUrl;

  /// Restaurant type label (maps to [ReviewRestaurant.primaryType]).
  final String? placeType;

  /// Star rating 1–5, null if untouched.
  final double? rating;

  /// Selected mood-category tag keys.
  final List<String> moodTags;

  /// Selected price-category tag key (single-select), null if none.
  final String? priceTag;

  /// Comment text, null/empty if untouched.
  final String? comment;

  /// Local filesystem paths of the originally-picked photos (NOT uploaded
  /// URLs). Re-picked from disk on restore; missing files are skipped.
  final List<String> localPhotoPaths;

  /// When this draft was saved — drives the "from [relative time]" copy in
  /// the restore dialog.
  final DateTime savedAt;

  /// All selected tag keys (mood + price) recombined — the screen stores
  /// them in one set.
  List<String> get allTagKeys => [...moodTags, ?priceTag];

  /// True when there's nothing worth restoring — used to avoid persisting an
  /// empty form.
  bool get isEmpty =>
      placeId == null &&
      (rating == null || rating == 0) &&
      moodTags.isEmpty &&
      priceTag == null &&
      (comment == null || comment!.isEmpty) &&
      localPhotoPaths.isEmpty;

  ReviewDraft copyWith({
    String? placeId,
    String? placeName,
    String? placePhotoUrl,
    String? placeType,
    double? rating,
    List<String>? moodTags,
    String? priceTag,
    String? comment,
    List<String>? localPhotoPaths,
    DateTime? savedAt,
  }) {
    return ReviewDraft(
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      placePhotoUrl: placePhotoUrl ?? this.placePhotoUrl,
      placeType: placeType ?? this.placeType,
      rating: rating ?? this.rating,
      moodTags: moodTags ?? this.moodTags,
      priceTag: priceTag ?? this.priceTag,
      comment: comment ?? this.comment,
      localPhotoPaths: localPhotoPaths ?? this.localPhotoPaths,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        if (placeId != null) 'placeId': placeId,
        if (placeName != null) 'placeName': placeName,
        if (placePhotoUrl != null) 'placePhotoUrl': placePhotoUrl,
        if (placeType != null) 'placeType': placeType,
        if (rating != null) 'rating': rating,
        'moodTags': moodTags,
        if (priceTag != null) 'priceTag': priceTag,
        if (comment != null) 'comment': comment,
        'localPhotoPaths': localPhotoPaths,
        'savedAt': savedAt.toIso8601String(),
      };

  factory ReviewDraft.fromJson(Map<String, dynamic> json) {
    return ReviewDraft(
      placeId: json['placeId'] as String?,
      placeName: json['placeName'] as String?,
      placePhotoUrl: json['placePhotoUrl'] as String?,
      placeType: json['placeType'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      moodTags: (json['moodTags'] as List?)?.whereType<String>().toList() ??
          const [],
      priceTag: json['priceTag'] as String?,
      comment: json['comment'] as String?,
      localPhotoPaths:
          (json['localPhotoPaths'] as List?)?.whereType<String>().toList() ??
              const [],
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
