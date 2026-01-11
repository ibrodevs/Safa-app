import 'package:dogo/data/network/api_service.dart';
import '../model/delivery_autocomplete_result.dart';
import '../model/delivery_reverse_geo.dart';
import 'osm_geo_api.dart';
import 'package:dio/dio.dart';

class DeliveryGeoRepository {
  final ApiService _api;
  final OsmGeoApi _osm;

  DeliveryGeoRepository(this._api)
      : _osm = OsmGeoApi(Dio());

  Future<DeliveryReverseGeo> getAddress({
    required double lat,
    required double lon,
  }) async {
    final json = await _osm.reverseRaw(lat: lat, lon: lon);
    return DeliveryReverseGeo.fromJson(json);
  }

  Future<List<DeliveryAutocompleteResult>> autocomplete(String query) async {
    final list = await _osm.autocompleteRaw(query);
    return list.map((e) => DeliveryAutocompleteResult.fromJson(e)).toList();
  }
}
