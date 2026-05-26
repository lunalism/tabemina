import '../../data/models/place_detail.dart';
import '../repositories/place_detail_repository.dart';

/// Use case: fetch full details for a Google Place by ID.
class GetPlaceDetail {
  const GetPlaceDetail(this._repository);

  final PlaceDetailRepository _repository;

  Future<PlaceDetail> call(
    String placeId, {
    required String languageCode,
  }) {
    return _repository.getPlaceDetail(placeId, languageCode: languageCode);
  }
}
