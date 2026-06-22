import '../entities/report_reason.dart';
import '../entities/review_entity.dart';

/// A new review the user just composed in the write-review form. The
/// repository is responsible for assigning [reviewId], [createdAt],
/// [updatedAt], and the resolved photo URLs after upload.
class ReviewDraftData {
  const ReviewDraftData({
    required this.userId,
    required this.userName,
    required this.placeId,
    required this.placeName,
    required this.rating,
    required this.comment,
    required this.moodTags,
    required this.priceTags,
    required this.language,
    this.userPhotoUrl,
    this.placeAddress,
    this.placeLat,
    this.placeLng,
  });

  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String placeId;
  final String placeName;
  final String? placeAddress;
  final double? placeLat;
  final double? placeLng;
  final double rating;
  final String comment;
  final List<String> moodTags;
  final List<String> priceTags;
  final String language;
}

/// Abstract review-storage contract.
///
/// The presentation layer talks to this interface only — never to Firestore
/// or Storage. Swapping backends means writing a new implementation, not
/// changing any screen code.
abstract class ReviewRepository {
  /// Mint a fresh review document id WITHOUT writing anything. The caller
  /// holds onto this stable id across submit attempts so a lost-ack retry
  /// re-targets the SAME document instead of creating a duplicate (see
  /// [submitReview] / [reviewExists]).
  String newReviewId();

  /// Whether a review document with [reviewId] already exists. The read rule
  /// is public, so this is always permitted — it's the dedup probe a retry
  /// runs before deciding whether the prior (possibly lost-ack) write
  /// actually committed.
  Future<bool> reviewExists(String reviewId);

  /// Write the review document at [reviewId] with already-uploaded
  /// [photoUrls]. The id is minted up-front by [newReviewId] and passed in so
  /// a retry re-targets the same doc (idempotent create). Photos are
  /// pre-uploaded to Storage by the write-review flow, so this is just a
  /// Firestore write. [photoStoragePaths] are the Storage object paths for
  /// those URLs, persisted so the photos can be deleted later. Returns the
  /// persisted entity (with [reviewId] and timestamps).
  ///
  /// Always a `set()` create — never a re-`set()` of an existing doc, which
  /// the Firestore rules route through the owner-only UPDATE path and reject.
  /// Callers MUST gate a retry on [reviewExists] and skip the write when the
  /// doc is already there.
  Future<ReviewEntity> submitReview(
    String reviewId,
    ReviewDraftData draft,
    List<String> photoUrls,
    List<String> photoStoragePaths,
  );

  /// Edit an existing review. [photoUrls] is the final ordered list (kept
  /// existing + newly pre-uploaded), with [photoStoragePaths] their Storage
  /// object paths. [removedStoragePaths] (preferred) and [removedPhotoUrls]
  /// (fallback for older reviews lacking stored paths) identify photos to
  /// delete from Storage. `createdAt` and `userId` are preserved;
  /// `updatedAt` is refreshed. Returns the updated entity.
  Future<ReviewEntity> updateReview(
    ReviewEntity review,
    List<String> photoUrls,
    List<String> photoStoragePaths,
    List<String> removedPhotoUrls,
    List<String> removedStoragePaths,
  );

  Future<List<ReviewEntity>> getReviewsForPlace(String placeId);

  Future<List<ReviewEntity>> getReviewsByUser(String userId);

  /// `createdAt` of the user's most recent review for [placeId], or null
  /// if they've never reviewed it. Used for the 24h per-place cooldown.
  Future<DateTime?> getLastReviewTimeForPlace(String userId, String placeId);

  /// Whether [userId] may post a new review for [placeId] right now — true
  /// if they've never reviewed it or their last review was 24h+ ago.
  Future<bool> canReviewPlace(String userId, String placeId);

  /// One-shot read of the newest reviews across all places (Home feed).
  Future<List<ReviewEntity>> getLatestReviews({int limit = 10});

  Stream<List<ReviewEntity>> watchReviewsForPlace(String placeId);

  Future<void> deleteReview(String reviewId);

  /// Report [reviewId] by [reporterUserId] with [reason]. Runs in a single
  /// Firestore transaction keyed on `reports/{reviewId}_{reporterUserId}`,
  /// so a user can report a review at most once. When the report pushes the
  /// review's reportCount to kReportThreshold the review is hidden. Returns
  /// [ReportOutcome.alreadyReported] (a no-op) when a prior report exists.
  Future<ReportOutcome> reportReview({
    required String reviewId,
    required String reporterUserId,
    required ReportReason reason,
  });
}
