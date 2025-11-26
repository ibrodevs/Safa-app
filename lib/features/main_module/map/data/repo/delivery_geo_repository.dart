import 'package:dogo/data/network/api_service.dart';

import '../model/delivery_autocomplete_result.dart';
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

  Future<List<DeliveryAutocompleteResult>> autocomplete(String query) async {
    final list = await _api.getDeliveryAutocompleteRaw(query);
    return list
        .map((e) => DeliveryAutocompleteResult.fromJson(e))
        .toList();
  }
}
