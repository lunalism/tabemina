import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/location_providers.dart';
import '../../data/datasources/places_api_datasource.dart';
import '../../data/models/nearby_restaurant.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/usecases/get_popular_restaurants.dart';

final _placesDatasourceProvider = Provider<PlacesApiDatasource>(
  (ref) => PlacesApiDatasource(),
);

final _homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(ref.watch(_placesDatasourceProvider)),
);

final _getPopularRestaurantsProvider = Provider<GetPopularRestaurants>(
  (ref) => GetPopularRestaurants(ref.watch(_homeRepositoryProvider)),
);

/// Popular restaurants near the user's current position.
///
/// Resolves [currentPositionProvider] first; if there's no fix, returns an
/// empty list rather than an error so the UI can show its "no nearby
/// restaurants" empty state without distinguishing causes.
final popularRestaurantsProvider =
    FutureProvider<List<NearbyRestaurant>>((ref) async {
  final position = await ref.watch(currentPositionProvider.future);
  if (position == null) return const [];
  return ref.read(_getPopularRestaurantsProvider)(
    latitude: position.latitude,
    longitude: position.longitude,
  );
});
