import 'package:dogo/data/network/api_service.dart';

import '../model/delivery_refs_models.dart';

/// Репозиторий справочников доставки (базары / проходы / контейнеры).
/// Базары кэшируются в памяти — их мало и они не меняются в рамках сессии.
class DeliveryRefsRepository {
  DeliveryRefsRepository({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;

  static List<BazarRef>? _bazarsCache;

  /// На телефоне нет смысла одновременно держать сотни обычных контейнерных
  /// маркеров: опубликованная карта уже отдаёт свои контейнеры отдельным слоем.
  /// Ограничение снижает JSON-парсинг, количество Widget/Polygon и нагрузку на
  /// GPU при входе в карту.
  static const int _maxBoundsPageSize = 96;
  static const int _maxBoundsCacheEntries = 20;
  static const Duration _boundsCacheTtl = Duration(seconds: 8);
  static final Map<String, _ContainerBoundsCacheEntry> _boundsCache = {};
  static final Map<String, Future<List<ContainerRef>>> _boundsInFlight = {};

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

  Future<ContainerRef> getContainer(int id) async {
    final json = await _api.getJson(
      'delivery/containers/$id/',
      fallbackError: 'Не удалось загрузить контейнер',
    );
    return ContainerRef.fromJson(json);
  }

  Future<List<ContainerRef>> loadContainersInBounds({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    int pageSize = 200,
  }) async {
    final effectivePageSize = pageSize.clamp(1, _maxBoundsPageSize).toInt();
    final key = _boundsKey(
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
      pageSize: effectivePageSize,
    );

    final now = DateTime.now();
    final cached = _boundsCache[key];
    if (cached != null) {
      if (cached.expiresAt.isAfter(now)) return cached.items;
      _boundsCache.remove(key);
    }

    // Два почти одновременных события карты (init + onMapReady) раньше могли
    // отправлять одинаковые запросы. Теперь один запрос делится между ними.
    final pending = _boundsInFlight[key];
    if (pending != null) return pending;

    final request = _loadContainersInBoundsUncached(
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
      pageSize: effectivePageSize,
    );
    _boundsInFlight[key] = request;

    try {
      final items = await request;
      _rememberBounds(key, items);
      return items;
    } finally {
      if (identical(_boundsInFlight[key], request)) {
        _boundsInFlight.remove(key);
      }
    }
  }

  Future<List<ContainerRef>> _loadContainersInBoundsUncached({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    required int pageSize,
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
        .toList(growable: false);
  }

  static void _rememberBounds(String key, List<ContainerRef> items) {
    if (_boundsCache.length >= _maxBoundsCacheEntries &&
        !_boundsCache.containsKey(key)) {
      _boundsCache.remove(_boundsCache.keys.first);
    }
    _boundsCache[key] = _ContainerBoundsCacheEntry(
      items: items,
      expiresAt: DateTime.now().add(_boundsCacheTtl),
    );
  }

  static String _boundsKey({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    required int pageSize,
  }) {
    int bucket(double value) => (value * 10000).round();
    return '${bucket(minLat)}:${bucket(maxLat)}:'
        '${bucket(minLon)}:${bucket(maxLon)}:$pageSize';
  }
}

final class _ContainerBoundsCacheEntry {
  const _ContainerBoundsCacheEntry({required this.items, required this.expiresAt});

  final List<ContainerRef> items;
  final DateTime expiresAt;
}
