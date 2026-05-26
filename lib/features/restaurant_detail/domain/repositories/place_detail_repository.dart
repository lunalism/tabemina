import '../../data/models/place_detail.dart';

/// Domain contract for fetching a single restaurant's full details.
///
/// [languageCode] is the app's currently selected language (en / ja / ko) —
/// passed through to Places so name / address / hours / editorial summary
/// come back localized.
abstract class PlaceDetailRepository {
  Future<PlaceDetail> getPlaceDetail(
    String placeId, {
    required String languageCode,
  });
}
