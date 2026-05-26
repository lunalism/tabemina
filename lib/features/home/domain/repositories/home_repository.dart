import '../../data/models/nearby_restaurant.dart';

/// Domain contract for Home-feed data.
///
/// Lives in the domain layer so the use case + UI never import the data
/// implementation directly. Concrete wiring is in [HomeRepositoryImpl].
abstract class HomeRepository {
  Future<List<NearbyRestaurant>> getPopularRestaurants({
    required double latitude,
    required double longitude,
  });

  Future<List<NearbyRestaurant>> getNearbyCafes({
    required double latitude,
    required double longitude,
  });
}
