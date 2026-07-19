import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/providers/connectivity_providers.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/utils/not_found_exception.dart';
import '../../data/datasources/place_detail_remote_datasource.dart';
import '../../data/models/place_detail.dart';
import '../../data/repositories/place_detail_repository_impl.dart';
import '../../domain/repositories/place_detail_repository.dart';
import '../../domain/usecases/get_place_detail.dart';

final _datasourceProvider = Provider<PlaceDetailRemoteDatasource>(
  (ref) => PlaceDetailRemoteDatasource(),
);

final _repositoryProvider = Provider<PlaceDetailRepository>(
  (ref) => PlaceDetailRepositoryImpl(ref.watch(_datasourceProvider)),
);

final _getPlaceDetailProvider = Provider<GetPlaceDetail>(
  (ref) => GetPlaceDetail(ref.watch(_repositoryProvider)),
);

/// Place details, keyed by `placeId`.
///
/// `.family` keys per-place; `autoDispose` keeps the cache bounded as users
/// browse around. Watches [appLocaleProvider] so changing the app language
/// re-fetches every active entry with localized name / address / hours
/// without needing manual invalidation from the language selector.
///
/// Self-heals after an offline failure, mirroring `latestReviewsProvider`
/// (C-1): on the offline → online TRANSITION, invalidate so the screen
/// reloads without a manual retry. Guarded so a successfully loaded screen
/// is never refetched on reconnect, and a not-found place (terminal — see
/// [NotFoundException]) is never pointlessly retried. A provider cannot
/// `ref.read` itself (Riverpod asserts on self-dependency), so the current
/// build's outcome is tracked with local flags instead of inspecting state.
final placeDetailProvider =
    FutureProvider.autoDispose.family<PlaceDetail, String>((ref, placeId) {
  var failed = false;
  var reconnectedMidFetch = false;
  ref.listen(connectivityStatusProvider, (prev, next) {
    final wasOffline = prev?.asData?.value == NetworkStatus.offline;
    final nowOnline = next.asData?.value == NetworkStatus.online;
    if (!wasOffline || !nowOnline) return;
    if (failed) {
      ref.invalidateSelf();
    } else {
      // Fetch still in flight; if it ends up failing, retry once then —
      // otherwise a reconnect during the in-flight window would strand the
      // screen on the error view even though the network is back.
      reconnectedMidFetch = true;
    }
  });
  final locale = ref.watch(appLocaleProvider);
  final future = ref.read(_getPlaceDetailProvider)(
    placeId,
    languageCode: locale.languageCode,
  );
  unawaited(future.then((_) {}, onError: (Object e, StackTrace _) {
    if (e is NotFoundException) return;
    failed = true;
    if (reconnectedMidFetch && ref.mounted) ref.invalidateSelf();
  }));
  return future;
});
