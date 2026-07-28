import '../../../../../data/network/api_service.dart';
import '../model/market_map_feature.dart';

final class MarketMapRepository {
  MarketMapRepository({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;

  Future<MarketMapCollection> loadPublished({int? bazarId}) async {
    final response = await _api.dio.get<dynamic>(
      'delivery/map/features/',
      queryParameters: {
        if (bazarId != null) 'bazar_id': bazarId,
        // Загружаем опубликованный набор один раз и фильтруем по масштабу
        // локально, чтобы панорамирование карты не создавало лишние запросы.
        'zoom': 22,
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
