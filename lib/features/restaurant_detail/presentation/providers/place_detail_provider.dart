import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_locale_provider.dart';
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
final placeDetailProvider =
    FutureProvider.autoDispose.family<PlaceDetail, String>((ref, placeId) {
  final locale = ref.watch(appLocaleProvider);
  return ref.read(_getPlaceDetailProvider)(
    placeId,
    languageCode: locale.languageCode,
  );
});
