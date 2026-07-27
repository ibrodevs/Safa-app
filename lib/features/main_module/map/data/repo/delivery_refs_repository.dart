import 'package:dogo/data/network/api_service.dart';

import '../model/delivery_refs_models.dart';

/// Репозиторий справочников доставки (базары / проходы / контейнеры).
/// Базары кэшируются в памяти — их мало и они не меняются в рамках сессии.
class DeliveryRefsRepository {
  DeliveryRefsRepository({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;

  static List<BazarRef>? _bazarsCache;

  List<Map<String, dynamic>> _resultsOf(Map<String, dynamic> json) {
    final results = json['results'];
    if (results is! List) return const [];
    return results
        .whereType<Map>()
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<BazarRef>> _loadBazars() async {
    final out = <BazarRef>[];
    var page = 1;

    while (true) {
      final json = await _api.getJson(
        'delivery/bazars/',
        queryParameters: {'page': page, 'page_size': 100},
        fallbackError: 'Не удалось загрузить список базаров',
      );

      out.addAll(_resultsOf(json).map(BazarRef.fromJson));

      if (json['next'] == null || page >= 10) break;
      page++;
    }

    return out;
  }

  /// Все базары (кэш) с локальным фильтром по подстроке.
  Future<List<BazarRef>> searchBazars(String query) async {
    final all = _bazarsCache ??= await _loadBazars();

    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;

    return all.where((b) => b.name.toLowerCase().contains(q)).toList();
  }

  Future<List<PassageRef>> searchPassages({
    String query = '',
    int? bazarId,
    int pageSize = 20,
  }) async {
    final q = query.trim();

    final json = await _api.getJson(
      'delivery/passages/',
      queryParameters: {
        'page_size': pageSize,
        if (q.isNotEmpty) 'q': q,
        if (bazarId != null) 'bazar_id': bazarId,
      },
      fallbackError: 'Не удалось загрузить список проходов',
    );

    return _resultsOf(json).map(PassageRef.fromJson).toList();
  }

  Future<List<ContainerRef>> searchContainers({
    String query = '',
    int? bazarId,
    int? passageId,
    int pageSize = 20,
  }) async {
    final q = query.trim();

    final json = await _api.getJson(
      'delivery/containers/',
      queryParameters: {
        'page_size': pageSize,
        if (q.isNotEmpty) 'q': q,
        if (bazarId != null) 'bazar_id': bazarId,
        if (passageId != null) 'passage_id': passageId,
      },
      fallbackError: 'Не удалось загрузить список контейнеров',
    );

    return _resultsOf(
      json,
    ).map(ContainerRef.fromJson).where((c) => c.isActive).toList();
  }

  Future<List<ContainerRef>> loadContainersInBounds({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    int pageSize = 200,
  }) async {
    final json = await _api.getJson(
      'delivery/containers/',
      queryParameters: {
        'page_size': pageSize,
        'min_lat': minLat,
        'max_lat': maxLat,
        'min_lon': minLon,
        'max_lon': maxLon,
      },
      fallbackError: 'Не удалось загрузить контейнеры',
    );

    return _resultsOf(json)
        .map(ContainerRef.fromJson)
        .where((c) => c.isActive && c.latValue != null && c.lonValue != null)
        .toList();
  }
}
