import '../../domain/models/review_draft.dart';

/// Placeholder review-post repository.
///
/// The real implementation will write to Firestore + Storage, but the UI
/// flow needs *something* to wait on so the post button can show a loading
/// state. Returns after a short delay to mimic a network round-trip.
class ReviewRepository {
  const ReviewRepository();

  Future<void> postReview(ReviewDraft draft) async {
    await Future.delayed(const Duration(milliseconds: 900));
  }
}
