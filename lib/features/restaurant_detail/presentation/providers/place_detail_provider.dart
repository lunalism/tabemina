import 'package:flutter_riverpod/flutter_riverpod.dart';

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
/// browse around. Combined with Riverpod's per-key caching, hitting back from
/// detail and re-opening the same restaurant short-circuits without a refetch
/// as long as something in the tree still listens to it.
final placeDetailProvider =
    FutureProvider.autoDispose.family<PlaceDetail, String>((ref, placeId) {
  return ref.read(_getPlaceDetailProvider)(placeId);
});
