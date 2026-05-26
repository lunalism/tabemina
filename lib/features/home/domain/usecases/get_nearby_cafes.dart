import '../../data/models/nearby_restaurant.dart';
import '../repositories/home_repository.dart';

/// Use case: fetch cafes near a position for the "Cafes nearby" carousel.
///
/// Mirrors [GetPopularRestaurants] in shape; kept as a separate seam so
/// cafe-specific business rules (e.g. show open-now first) can land here
/// without entangling the restaurant query.
class GetNearbyCafes {
  const GetNearbyCafes(this._repository);

  final HomeRepository _repository;

  Future<List<NearbyRestaurant>> call({
    required double latitude,
    required double longitude,
    required String languageCode,
  }) {
    return _repository.getNearbyCafes(
      latitude: latitude,
      longitude: longitude,
      languageCode: languageCode,
    );
  }
}
