import 'package:dio/dio.dart';
import 'package:dogo/data/network/api_service.dart';

import '../model/delivery_autocomplete_result.dart';
import '../model/delivery_reverse_geo.dart';
import 'osm_geo_api.dart';

class DeliveryGeoRepository {
  final ApiService _api;
  final OsmGeoApi _osm;

  DeliveryGeoRepository(this._api) : _osm = OsmGeoApi(Dio());

  static final RegExp _coordinateOnlyAddress = RegExp(
    r'^\s*-?\d{1,3}(?:\.\d+)?\s*[,;]\s*-?\d{1,3}(?:\.\d+)?\s*$',
  );
  static final RegExp _addressLetter = RegExp(r'[A-Za-zА-Яа-яЁё]');

  static bool _isReadableAddress(String value) {
    final address = value.trim();
    return address.isNotEmpty &&
        !_coordinateOnlyAddress.hasMatch(address) &&
        _addressLetter.hasMatch(address);
  }

  Future<DeliveryReverseGeo> getAddress({
    required double lat,
    required double lon,
    bool preferPublicAddress = false,
  }) async {
    // 1. Всегда сначала запрашиваем бэкенд: на бэкенде работает прямой
    // Яндекс-геокодер, возвращающий точные адреса Дордоя
    // («0-й проход, 10Б, рынок Китай, рынок Дордой, Бишкек») и адреса города.
    try {
      final response = await _api.dio.get<dynamic>(
        'delivery/geo/reverse/',
        queryParameters: {'lat': lat, 'lon': lon},
      );
      final data = response.data;
      if (response.statusCode == 200 && data is Map) {
        final json = Map<String, dynamic>.from(data);
        final address = json['address']?.toString().trim() ?? '';
        final source = json['source']?.toString().trim() ?? '';
        if (source != 'coordinates' && _isReadableAddress(address)) {
          return DeliveryReverseGeo.fromJson(json);
        }
      }
    } catch (_) {
      // Если бэкенд недоступен, работает клиентский геокодер ниже.
    }

    // 2. Резервный клиентский геокодер (Яндекс -> Nominatim -> Photon)
    final json = await _osm.reverseRaw(lat: lat, lon: lon);
    final external = DeliveryReverseGeo.fromJson(json);
    if (_isReadableAddress(external.address)) return external;
    throw StateError('Readable address was not found for the selected point');
  }

  Future<List<DeliveryAutocompleteResult>> autocomplete(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];

    try {
      final response = await _api.dio.get<dynamic>(
        'delivery/geo/autocomplete/',
        queryParameters: {'q': q},
      );
      final data = response.data;
      if (response.statusCode == 200 && data is Map) {
        final results = data['results'];
        if (results is List && results.isNotEmpty) {
          return results
              .whereType<Map>()
              .map(
                (e) => DeliveryAutocompleteResult.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList();
        }
      }
    } catch (_) {
      // Fallback to client-side OSM if backend is unreachable
    }

    final list = await _osm.autocompleteRaw(q);
    return list.map((e) => DeliveryAutocompleteResult.fromJson(e)).toList();
  }
}
