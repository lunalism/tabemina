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

/// Reviews could not be fetched from the backend and no cached copy exists
/// (e.g. offline on a fresh install). Callers surface this as a retriable
/// error state rather than an empty list — without it, an offline cold start
/// renders as a fake "no reviews yet".
class ReviewsUnavailableException implements Exception {
  const ReviewsUnavailableException();

  @override
  String toString() =>
      'ReviewsUnavailableException: network is unreachable and no cached '
      'reviews exist';
}

/// What the retry dedup probe found at a review id.
///
/// Deliberately three-valued rather than a bool: "a document is there" and "the
/// server has accepted a document" are different facts, and conflating them
/// makes a locally-queued write look like a published review. Only [committed]
/// may be treated as a success — it is the sole state that licenses clearing
/// the draft, firing analytics, or telling the user their review is live.
enum ReviewWriteState {
  /// Nothing at this id. The prior attempt never landed; writing is safe.
  absent,

  /// A document exists but is still an unacknowledged LOCAL mutation — the
  /// backend has not accepted it and may yet reject it (rules, expired auth,
  /// oversize field). Not a success, and not worth re-writing: the queued write
  /// will be delivered on its own.
  pending,

  /// A document exists and is server-confirmed. The only success state.
  committed,
}

/// How a review deletion ended.
///
/// Two-valued because only the doc-delete phase can end ambiguously. Everything
/// that means "nothing was issued" — including a timeout on the path READ that
/// precedes the delete — still throws, so callers cannot mistake it for a
/// deletion in progress. That distinction is the whole reason this is a return
/// value rather than the caller inspecting [TimeoutException]: both phases throw
/// the same type, and treating a read timeout as queued would tell the user a
/// review was deleted while it sat there untouched.
enum ReviewDeleteOutcome {
  /// The doc delete was ACKED by the server. Storage cleanup ran best-effort;
  /// a failure there leaves an orphan blob and is deliberately not surfaced.
  deleted,

  /// The doc delete was handed to Firestore but not acked in time. It is PENDING:
  /// latency compensation has already removed the review from the local cache, so
  /// from the user's point of view it is gone, and reporting a failure while they
  /// watch it disappear reads as a broken app. Storage cleanup was skipped on
  /// purpose.
  ///
  /// Pending is not the same as certain. A queued mutation can still be rejected
  /// (auth expiring during a long offline stretch, a rules change), in which case
  /// Firestore rolls the local delete back and the review REAPPEARS after the UI
  /// has already said it was deleted. Nothing currently observes that, because
  /// nothing observes the ack — the same gap that leaves the write flow's queued
  /// states unresolved and the review cooldown stale after a rejection. Tracked
  /// for v1.1; treating it as success is the accepted interim trade, since the
  /// alternative reports a failure that in the overwhelming majority of cases did
  /// not happen.
  queued,
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
  /// [submitReview] / [probeReviewWrite]).
  String newReviewId();

  /// The dedup probe a retry runs before deciding whether the prior (possibly
  /// lost-ack) write actually committed. The read rule is public, so this is
  /// always permitted.
  ///
  /// Returns [ReviewWriteState] rather than a bool because a local read can see
  /// the caller's OWN queued write. Implementations MUST NOT report a write the
  /// backend has not acknowledged as [ReviewWriteState.committed] — that is
  /// what keeps "retry is safe" true rather than merely plausible.
  Future<ReviewWriteState> probeReviewWrite(String reviewId);

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
  /// Callers MUST gate a retry on [probeReviewWrite] and skip the write unless
  /// it reports [ReviewWriteState.absent].
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
  /// Throws [ReviewsUnavailableException] when the backend is unreachable and
  /// no cached copy exists — an empty result then means "no reviews", never
  /// "couldn't load".
  Future<List<ReviewEntity>> getLatestReviews({int limit = 10});

  Stream<List<ReviewEntity>> watchReviewsForPlace(String placeId);

  /// Delete [reviewId] and its photos, doc-first.
  ///
  /// Returns [ReviewDeleteOutcome.deleted] on a server-acked delete and
  /// [ReviewDeleteOutcome.queued] when the delete was handed off but not acked
  /// in time. THROWS for everything that left the review untouched — including a
  /// timeout on the path read, which must not read as queued.
  Future<ReviewDeleteOutcome> deleteReview(String reviewId);

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
