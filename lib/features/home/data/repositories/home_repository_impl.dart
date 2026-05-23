import '../../domain/repositories/home_repository.dart';
import '../datasources/places_api_datasource.dart';
import '../models/nearby_restaurant.dart';

/// Default [HomeRepository] backed by Google Places.
///
/// Sorts the popularity-ranked results by rating (desc) so the carousel
/// leads with the highest-rated spots. Restaurants without a rating sink
/// to the bottom.
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._datasource);

  final PlacesApiDatasource _datasource;

  @override
  Future<List<NearbyRestaurant>> getPopularRestaurants({
    required double latitude,
    required double longitude,
  }) async {
    final results = await _datasource.searchNearbyRestaurants(
      latitude: latitude,
      longitude: longitude,
    );
    results.sort((a, b) {
      final ar = a.rating ?? -1;
      final br = b.rating ?? -1;
      return br.compareTo(ar);
    });
    return results;
  }
}
