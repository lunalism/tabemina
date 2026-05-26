import '../../data/models/place_detail.dart';

/// Domain contract for fetching a single restaurant's full details.
abstract class PlaceDetailRepository {
  Future<PlaceDetail> getPlaceDetail(String placeId);
}
