import '../../data/models/nearby_restaurant.dart';

/// Domain contract for Home-feed data.
///
/// Lives in the domain layer so the use case + UI never import the data
/// implementation directly. Concrete wiring is in [HomeRepositoryImpl].
///
/// [languageCode] is the app's currently selected language (en / ja / ko) —
/// passed through to the Places API so restaurant names, addresses and
/// editorial summaries come back localized.
abstract class HomeRepository {
  Future<List<NearbyRestaurant>> getPopularRestaurants({
    required double latitude,
    required double longitude,
    required String languageCode,
  });

  Future<List<NearbyRestaurant>> getNearbyCafes({
    required double latitude,
    required double longitude,
    required String languageCode,
  });
}
