import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_review_repository.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/review_repository.dart';
import 'auth_providers.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return FirebaseReviewRepository();
});

/// Live reviews for one Place ID, ordered newest-first. The stream variant
/// keeps the detail page in sync if the user posts a review and pops back —
/// no manual invalidate needed.
final placeReviewsProvider =
    StreamProvider.family<List<ReviewEntity>, String>((ref, placeId) {
  return ref.watch(reviewRepositoryProvider).watchReviewsForPlace(placeId);
});

/// Reviews written by the signed-in user (My Page → Reviews). Returns an
/// empty list when the user is not signed in.
final userReviewsProvider = FutureProvider<List<ReviewEntity>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.read(reviewRepositoryProvider).getReviewsByUser(user.uid);
});

/// 10 newest reviews across all places — Home feed's "Latest reviews".
final latestReviewsProvider = FutureProvider<List<ReviewEntity>>((ref) {
  return ref.watch(reviewRepositoryProvider).getLatestReviews(limit: 10);
});
