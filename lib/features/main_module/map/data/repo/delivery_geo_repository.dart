import 'package:dio/dio.dart';
import 'package:dogo/data/network/api_service.dart';

import '../model/delivery_autocomplete_result.dart';
import '../model/delivery_reverse_geo.dart';
import 'osm_geo_api.dart';

class DeliveryGeoRepository {
  final ApiService _api;
  final OsmGeoApi _osm;

  DeliveryGeoRepository(this._api) : _osm = OsmGeoApi(Dio());

  Future<DeliveryReverseGeo> getAddress({
    required double lat,
    required double lon,
  }) async {
    // Сначала спрашиваем наш backend. Если точка попала внутрь контейнера,
    // созданного в админ-панели, backend вернёт иерархию Safa:
    // базар → район → проход → контейнер. Это важнее внешнего адреса улицы.
    try {
      final response = await _api.dio.get<dynamic>(
        'delivery/geo/reverse/',
        queryParameters: {'lat': lat, 'lon': lon},
      );
      final data = response.data;
      if (response.statusCode == 200 && data is Map) {
        final json = Map<String, dynamic>.from(data);
        final address = json['address']?.toString().trim() ?? '';
        if (address.isNotEmpty) {
          return DeliveryReverseGeo.fromJson(json);
        }
      }
    } catch (_) {
      // Если backend временно недоступен, карта всё равно должна работать.
    }

    final json = await _osm.reverseRaw(lat: lat, lon: lon);
    return DeliveryReverseGeo.fromJson(json);
  }

  Future<List<DeliveryAutocompleteResult>> autocomplete(String query) async {
    final list = await _osm.autocompleteRaw(query);
    return list.map((e) => DeliveryAutocompleteResult.fromJson(e)).toList();
  }
}
