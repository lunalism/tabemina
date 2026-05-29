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

/// Whether the signed-in user may post a new review for [placeId] right now
/// (24h per-place cooldown). False when signed out — they can't post anyway.
/// Uses [currentUserProvider] rather than FirebaseAuth so the presentation
/// layer stays Firebase-free.
final canReviewPlaceProvider =
    FutureProvider.family<bool, String>((ref, placeId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return ref.read(reviewRepositoryProvider).canReviewPlace(user.uid, placeId);
});

/// Remaining cooldown for [placeId], or null if the user can review now
/// (no prior review, 24h elapsed, or signed out). Drives the cooldown
/// banner / dialog copy.
final reviewCooldownRemainingProvider =
    FutureProvider.family<Duration?, String>((ref, placeId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final repo = ref.read(reviewRepositoryProvider);
  final lastTime = await repo.getLastReviewTimeForPlace(user.uid, placeId);
  if (lastTime == null) return null;
  final elapsed = DateTime.now().difference(lastTime);
  const cooldown = Duration(hours: 24);
  if (elapsed >= cooldown) return null;
  return cooldown - elapsed;
});
