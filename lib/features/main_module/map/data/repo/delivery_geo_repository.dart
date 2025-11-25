
import '../../../../../data/network/api_service.dart';
import '../model/delivery_reverse_geo.dart';

class DeliveryGeoRepository {
  final ApiService _api;

  DeliveryGeoRepository(this._api);

  Future<DeliveryReverseGeo> getAddress({
    required double lat,
    required double lon,
  }) {
    return _api.getDeliveryReverseGeo(lat: lat, lon: lon);
  }
}
