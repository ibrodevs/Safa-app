import 'package:dio/dio.dart';
import 'package:yandex_maps_mapkit_lite/mapkit.dart' as ykit;

class RoutingService {
  static const _baseUrl =
      'https://routing.api.2gis.com/routing/7.0.0/global';

  static const _apiKey = 'c65e5972-5592-4197-9dd2-e43bdcfd83fd';

  final Dio _dio;

  RoutingService(Dio dio) : _dio = dio;

  Future<List<ykit.Point>> buildWalkingRoute(
      List<ykit.Point> points,
      ) async {
    if (points.length < 2) return const [];

    final body = {
      'points': points
          .map((p) => {
        'type': 'walking',
        'lon': p.longitude,
        'lat': p.latitude,
      })
          .toList(),
      'transport': 'walking',
      'locale': 'ru',
      'output': 'detailed',
    };

    final resp = await _dio.post<dynamic>(
      _baseUrl,
      queryParameters: {'key': _apiKey},
      data: body,
      options: Options(
        headers: {'Content-Type': 'application/json'},
      ),
    );

    final data = resp.data as Map<String, dynamic>;
    if (data['status']?.toString() != 'OK') {
      throw Exception('Route status: ${data['status']}');
    }

    final result = data['result'] as List?;
    if (result == null || result.isEmpty) return const [];

    final first = result.first as Map<String, dynamic>;

    final maneuvers = first['maneuvers'] as List? ?? const [];
    final List<ykit.Point> routePoints = [];

    for (final m in maneuvers.whereType<Map<String, dynamic>>()) {
      final outPath = m['outcoming_path'] as Map<String, dynamic>?;
      if (outPath == null) continue;

      final geometries = outPath['geometry'] as List? ?? const [];
      for (final g in geometries.whereType<Map<String, dynamic>>()) {
        final selection = g['selection']?.toString();
        if (selection == null || !selection.startsWith('LINESTRING(')) {
          continue;
        }

        final content = selection
            .substring('LINESTRING('.length, selection.length - 1)
            .trim();

        if (content.isEmpty) continue;

        for (final pair in content.split(',')) {
          final parts = pair.trim().split(RegExp(r'\s+'));
          if (parts.length < 2) continue;
          final lon = double.tryParse(parts[0]);
          final lat = double.tryParse(parts[1]);
          if (lat == null || lon == null) continue;

          routePoints.add(ykit.Point(latitude: lat, longitude: lon));
        }
      }
    }

    return routePoints;
  }
}
