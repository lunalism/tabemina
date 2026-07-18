import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_locale_provider.dart';
import '../../core/providers/connectivity_providers.dart';
import '../../core/services/connectivity_service.dart';
import '../../data/repositories/firebase_review_repository.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/review_repository.dart';
import '../../features/write_review/data/services/draft_storage_service.dart';
import 'auth_providers.dart';
import 'block_providers.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return FirebaseReviewRepository();
});

/// SharedPreferences-backed store for the single in-progress review draft.
final draftStorageServiceProvider = Provider<DraftStorageService>((ref) {
  return DraftStorageService(ref.read(sharedPreferencesProvider));
});

/// Whether a saved review draft currently exists — drives the "draft in
/// progress" hint on the My Page reviews empty state. Re-runs when
/// invalidated (e.g. after the write-review screen saves or clears a draft).
final hasDraftProvider = FutureProvider<bool>((ref) {
  return ref.read(draftStorageServiceProvider).hasDraft();
});

/// Live reviews for one Place ID, ordered newest-first. The stream variant
/// keeps the detail page in sync if the user posts a review and pops back —
/// no manual invalidate needed.
///
/// This is the isHidden-filtered set (B-2-1) and is the AGGREGATION source —
/// the review count badge and any future rating average read from here, so a
/// blocked author's review still counts toward the restaurant. Block is
/// personal, not a rule violation.
final placeReviewsProvider =
    StreamProvider.family<List<ReviewEntity>, String>((ref, placeId) {
  // The repository stream reports an offline empty cache as a
  // ReviewsUnavailableException error EVENT (the subscription stays alive —
  // see watchReviewsForPlace). Offline (or connectivity unknown) that is
  // surfaced immediately so the detail page shows its error + retry state.
  // While ONLINE the same event usually fires transiently — a cold listen
  // can deliver a cache-first empty snapshot moments before the server one —
  // but "online" only means a network interface is up (captive portal /
  // backend outage still report online), so the error can't simply be
  // dropped: with no server snapshot following, that would leave the section
  // loading forever. Instead hold it for a short grace period and emit it
  // only if no snapshot arrives in time.
  const grace = Duration(seconds: 4);
  final controller = StreamController<List<ReviewEntity>>();
  Timer? pendingError;
  final sub =
      ref.watch(reviewRepositoryProvider).watchReviewsForPlace(placeId).listen(
    (reviews) {
      pendingError?.cancel();
      pendingError = null;
      controller.add(reviews);
    },
    onError: (Object e, StackTrace st) {
      final online = ref.read(connectivityStatusProvider).asData?.value ==
          NetworkStatus.online;
      if (e is ReviewsUnavailableException && online) {
        pendingError ??= Timer(grace, () => controller.addError(e, st));
      } else {
        pendingError?.cancel();
        pendingError = null;
        controller.addError(e, st);
      }
    },
    onDone: () {
      pendingError?.cancel();
      pendingError = null;
      controller.close();
    },
  );
  ref.onDispose(() {
    pendingError?.cancel();
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});

/// [placeReviewsProvider] with blocked authors removed — the RENDERED list for
/// the detail page. Layered on top so aggregation stays on the unfiltered set
/// (blocked reviews keep counting toward the average); only the blocker's
/// visible list loses them. Reacts live to block/unblock via
/// [blockedUserIdsProvider].
final visiblePlaceReviewsProvider =
    Provider.family<AsyncValue<List<ReviewEntity>>, String>((ref, placeId) {
  final reviews = ref.watch(placeReviewsProvider(placeId));
  final blocked = ref.watch(blockedUserIdsProvider).asData?.value ?? const {};
  return reviews.whenData(
    (list) => list.where((r) => !blocked.contains(r.userId)).toList(),
  );
});

/// Reviews written by the signed-in user (My Page → Reviews). Returns an
/// empty list when the user is not signed in.
final userReviewsProvider = FutureProvider<List<ReviewEntity>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  return ref.read(reviewRepositoryProvider).getReviewsByUser(user.uid);
});

/// 10 newest reviews across all places — Home feed's "Latest reviews".
///
/// Self-heals after an offline cold start: an offline launch resolves to the
/// error state (see ReviewsUnavailableException), and without this listener
/// it would sit there until a manual retry / pull-to-refresh. Guarded to the
/// offline → online TRANSITION only, so emissions while already online (e.g.
/// wifi → cellular) don't refetch.
final latestReviewsProvider = FutureProvider<List<ReviewEntity>>((ref) {
  ref.listen(connectivityStatusProvider, (prev, next) {
    final wasOffline = prev?.asData?.value == NetworkStatus.offline;
    final nowOnline = next.asData?.value == NetworkStatus.online;
    if (wasOffline && nowOnline) ref.invalidateSelf();
  });
  return ref.watch(reviewRepositoryProvider).getLatestReviews(limit: 10);
});

/// [latestReviewsProvider] with blocked authors removed — the rendered home
/// feed. Reacts live to block/unblock via [blockedUserIdsProvider].
final visibleLatestReviewsProvider =
    Provider<AsyncValue<List<ReviewEntity>>>((ref) {
  final reviews = ref.watch(latestReviewsProvider);
  final blocked = ref.watch(blockedUserIdsProvider).asData?.value ?? const {};
  return reviews.whenData(
    (list) => list.where((r) => !blocked.contains(r.userId)).toList(),
  );
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
