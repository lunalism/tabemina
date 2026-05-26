import '../../domain/repositories/place_detail_repository.dart';
import '../datasources/place_detail_remote_datasource.dart';
import '../models/place_detail.dart';

class PlaceDetailRepositoryImpl implements PlaceDetailRepository {
  PlaceDetailRepositoryImpl(this._datasource);

  final PlaceDetailRemoteDatasource _datasource;

  @override
  Future<PlaceDetail> getPlaceDetail(String placeId) {
    return _datasource.fetch(placeId);
  }
}
