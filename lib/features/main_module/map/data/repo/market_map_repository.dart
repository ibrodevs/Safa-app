import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../../../data/network/api_service.dart';
import '../model/market_map_feature.dart';

final class MarketMapRepository {
  MarketMapRepository({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;

  static const int _maxCacheEntries = 20;
  static const Duration _cacheTtl = Duration(seconds: 60);
  static final Map<String, _MarketMapCacheEntry> _cache = {};
  static final Map<String, Future<MarketMapCollection>> _inFlight = {};
  static final Map<String, String> _etags = {};

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
    final effectiveMaxContainers = _effectiveMaxContainers(
      zoom: zoom,
      requested: maxContainers,
    );
    final key = _requestKey(
      bazarId: bazarId,
      zoom: zoom,
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
      centerLat: centerLat,
      centerLon: centerLon,
      maxContainers: effectiveMaxContainers,
    );

    final now = DateTime.now();
    final cached = _cache[key];
    if (cached != null) {
      if (cached.expiresAt.isAfter(now)) return cached.collection;
    }

    // initState и onMapReady могут сработать почти одновременно. Коалесим
    // одинаковые запросы, чтобы не грузить сеть и JSON-парсер дважды.
    final pending = _inFlight[key];
    if (pending != null) return pending;

    final request = _loadPublishedUncached(
      cacheKey: key,
      staleCollection: cached?.collection,
      bazarId: bazarId,
      zoom: zoom,
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
      centerLat: centerLat,
      centerLon: centerLon,
      maxContainers: effectiveMaxContainers,
    );
    _inFlight[key] = request;

    try {
      final collection = await request;
      _remember(key, collection);
      return collection;
    } finally {
      if (identical(_inFlight[key], request)) {
        _inFlight.remove(key);
      }
    }
  }

  Future<MarketMapCollection> _loadPublishedUncached({
    required String cacheKey,
    required MarketMapCollection? staleCollection,
    required int? bazarId,
    required int? zoom,
    required double? minLat,
    required double? maxLat,
    required double? minLon,
    required double? maxLon,
    required double? centerLat,
    required double? centerLon,
    required int maxContainers,
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
        'max_containers': maxContainers,
      },
      options: Options(
        headers: {if (_etags[cacheKey] case final etag?) 'If-None-Match': etag},
        validateStatus: (status) =>
            status != null &&
            ((status >= 200 && status < 300) || status == 304),
      ),
    );

    if (response.statusCode == 304 && staleCollection != null) {
      return staleCollection;
    }
    final etag = response.headers.value('etag');
    if (etag != null && etag.isNotEmpty) _etags[cacheKey] = etag;

    final data = response.data;
    late final Map<String, dynamic> normalized;
    if (data is Map<String, dynamic>) {
      normalized = data;
    } else if (data is Map) {
      normalized = Map<String, dynamic>.from(data);
    } else {
      throw const FormatException('Некорректный ответ карты базаров');
    }

    final rawFeatures = normalized['features'];
    if (rawFeatures is List && rawFeatures.length >= 48) {
      try {
        // Большой GeoJSON парсим вне UI-isolate. Именно JSON -> model раньше
        // мог давать заметный фриз в момент появления карты на слабых Android.
        return await compute(_parseMarketMapCollection, normalized);
      } catch (_) {
        // На редкой платформе/объекте, который нельзя передать в isolate,
        // сохраняем безопасный синхронный fallback.
      }
    }

    return MarketMapCollection.fromJson(normalized);
  }

  static int _effectiveMaxContainers({
    required int? zoom,
    required int? requested,
  }) {
    final z = zoom ?? 17;
    final hardLimit = z < 15
        ? 0
        : z == 15
        ? 24
        : z == 16
        ? 48
        : 72;
    if (requested == null) return hardLimit;
    return requested.clamp(0, hardLimit).toInt();
  }

  static void _remember(String key, MarketMapCollection collection) {
    if (_cache.length >= _maxCacheEntries && !_cache.containsKey(key)) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
      _etags.remove(oldestKey);
    }
    _cache[key] = _MarketMapCacheEntry(
      collection: collection,
      expiresAt: DateTime.now().add(_cacheTtl),
    );
  }

  static String _requestKey({
    required int? bazarId,
    required int? zoom,
    required double? minLat,
    required double? maxLat,
    required double? minLon,
    required double? maxLon,
    required double? centerLat,
    required double? centerLon,
    required int maxContainers,
  }) {
    String bucket(double? value) =>
        value == null ? '-' : (value * 10000).round().toString();
    return '${bazarId ?? '-'}:${zoom ?? '-'}:'
        '${bucket(minLat)}:${bucket(maxLat)}:${bucket(minLon)}:${bucket(maxLon)}:'
        '${bucket(centerLat)}:${bucket(centerLon)}:$maxContainers';
  }
}

MarketMapCollection _parseMarketMapCollection(Map<String, dynamic> json) {
  return MarketMapCollection.fromJson(json);
}

final class _MarketMapCacheEntry {
  const _MarketMapCacheEntry({
    required this.collection,
    required this.expiresAt,
  });

  final MarketMapCollection collection;
  final DateTime expiresAt;
}
