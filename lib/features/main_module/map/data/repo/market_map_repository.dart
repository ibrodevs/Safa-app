import '../../../../../data/network/api_service.dart';
import '../model/market_map_feature.dart';

final class MarketMapRepository {
  MarketMapRepository({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;

  Future<MarketMapCollection> loadPublished({
    int? bazarId,
    int? zoom,
    double? minLat,
    double? maxLat,
    double? minLon,
    double? maxLon,
    double? centerLat,
    double? centerLon,
    int? maxContainers,
  }) async {
    final response = await _api.dio.get<dynamic>(
      'delivery/map/features/',
      queryParameters: {
        if (bazarId != null) 'bazar_id': bazarId,
        if (zoom != null) 'zoom': zoom,
        if (minLat != null) 'min_lat': minLat,
        if (maxLat != null) 'max_lat': maxLat,
        if (minLon != null) 'min_lon': minLon,
        if (maxLon != null) 'max_lon': maxLon,
        if (centerLat != null) 'center_lat': centerLat,
        if (centerLon != null) 'center_lon': centerLon,
        if (maxContainers != null) 'max_containers': maxContainers,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return MarketMapCollection.fromJson(data);
    }
    if (data is Map) {
      return MarketMapCollection.fromJson(Map<String, dynamic>.from(data));
    }
    throw const FormatException('Некорректный ответ карты базаров');
  }
}
