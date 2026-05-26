import '../../data/models/nearby_restaurant.dart';
import '../repositories/home_repository.dart';

/// Use case: fetch popular restaurants near a position.
///
/// One-liner today, but keeps the seam in place for when "popular" gains
/// business rules (open-now filter, freshness window, etc.) that don't
/// belong in the repository.
class GetPopularRestaurants {
  const GetPopularRestaurants(this._repository);

  final HomeRepository _repository;

  Future<List<NearbyRestaurant>> call({
    required double latitude,
    required double longitude,
    required String languageCode,
  }) {
    return _repository.getPopularRestaurants(
      latitude: latitude,
      longitude: longitude,
      languageCode: languageCode,
    );
  }
}
