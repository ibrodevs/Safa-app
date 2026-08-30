import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

/// Builds a road route while preserving the business order of all stops.
///
/// OSRM returns routes in recommendation order, but we still compare the
/// alternatives explicitly: the fastest route wins, with distance used as a
/// tie-breaker. Pickup/drop-off points are never reordered.
final class OptimalRoadRouteService {
  OptimalRoadRouteService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
            ),
          );

  final Dio _dio;

  Future<List<LatLng>> build(List<LatLng> stops) async {
    if (stops.length < 2) return const [];
    final coordinatePath = stops
        .map((point) => '${point.longitude},${point.latitude}')
        .join(';');

    try {
      final response = await _dio.get<dynamic>(
        'https://router.project-osrm.org/route/v1/driving/$coordinatePath',
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
          'steps': 'false',
          'alternatives': '3',
          'continue_straight': 'false',
          'radiuses': List.filled(stops.length, 'unlimited').join(';'),
        },
      );
      final payload = response.data;
      final routes = payload is Map ? payload['routes'] : null;
      if (routes is! List || routes.isEmpty) return const [];

      final best = selectBestRoute(routes);
      final geometry = best?['geometry'];
      final coordinates = geometry is Map ? geometry['coordinates'] : null;
      if (coordinates is! List) return const [];

      final points = <LatLng>[];
      for (final coordinate in coordinates) {
        if (coordinate is! List || coordinate.length < 2) continue;
        final longitude = coordinate[0];
        final latitude = coordinate[1];
        if (longitude is! num || latitude is! num) continue;
        final point = LatLng(latitude.toDouble(), longitude.toDouble());
        if (points.isEmpty ||
            const Distance().as(LengthUnit.Meter, points.last, point) > 0.5) {
          points.add(point);
        }
      }
      return points.length >= 2 ? points : const [];
    } catch (_) {
      // A straight fallback would cut through buildings and mislead users.
      return const [];
    }
  }

  static Map<dynamic, dynamic>? selectBestRoute(List<dynamic> routes) {
    final candidates = routes.whereType<Map>().where((route) {
      return _metric(route['duration']) != null &&
          _metric(route['distance']) != null;
    }).toList();
    if (candidates.isEmpty) {
      return routes.whereType<Map>().firstOrNull;
    }

    candidates.sort((left, right) {
      final durationCompare = _metric(
        left['duration'],
      )!.compareTo(_metric(right['duration'])!);
      if (durationCompare != 0) return durationCompare;
      return _metric(left['distance'])!.compareTo(_metric(right['distance'])!);
    });
    return candidates.first;
  }

  static double? _metric(dynamic value) {
    if (value is num && value.isFinite && value >= 0) {
      return value.toDouble();
    }
    return null;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
