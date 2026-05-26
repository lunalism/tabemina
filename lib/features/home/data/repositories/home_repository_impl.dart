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

  /// Global fast-food chains we don't want crowding the "Popular near you"
  /// feed. Match is case-insensitive substring against the venue name.
  ///
  /// Deliberately narrow — only the biggest international chains. Japanese
  /// chains (yoshinoya, sukiya, coco ichibanya...) are legitimate local
  /// restaurants users *want* to see, so they stay.
  static const _globalChainBlocklist = {
    'starbucks',
    'mcdonalds',
    "mcdonald's",
    'burger king',
    'kfc',
    'subway',
    'dominos',
    "domino's",
    'pizza hut',
    'wendys',
    "wendy's",
    'taco bell',
    'dunkin',
  };

  static const _popularResultCount = 10;

  @override
  Future<List<NearbyRestaurant>> getPopularRestaurants({
    required double latitude,
    required double longitude,
  }) async {
    final results = await _datasource.searchNearbyRestaurants(
      latitude: latitude,
      longitude: longitude,
    );
    final filtered = results.where(_isNotGlobalChain).toList();
    filtered.sort(_byRatingDesc);
    return filtered.take(_popularResultCount).toList();
  }

  @override
  Future<List<NearbyRestaurant>> getNearbyCafes({
    required double latitude,
    required double longitude,
  }) async {
    final results = await _datasource.searchNearbyCafes(
      latitude: latitude,
      longitude: longitude,
    );
    results.sort(_byRatingDesc);
    return results;
  }

  static bool _isNotGlobalChain(NearbyRestaurant r) {
    final name = r.name.toLowerCase();
    return !_globalChainBlocklist.any(name.contains);
  }

  static int _byRatingDesc(NearbyRestaurant a, NearbyRestaurant b) {
    final ar = a.rating ?? -1;
    final br = b.rating ?? -1;
    return br.compareTo(ar);
  }
}
