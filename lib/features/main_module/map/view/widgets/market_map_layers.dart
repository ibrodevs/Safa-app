import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/model/market_map_feature.dart';

final class MarketMapRenderData {
  const MarketMapRenderData({
    required this.polygons,
    required this.polylines,
  });

  final List<Polygon> polygons;
  final List<Polyline> polylines;

  factory MarketMapRenderData.fromFeatures(
    Iterable<MarketMapFeature> features, {
    required double zoom,
  }) {
    final polygons = <Polygon>[];
    final polylines = <Polyline>[];

    for (final feature in features) {
      if (feature.isContainer || feature.minZoom > zoom) continue;
      final border = _parseColor(feature.strokeColor, const Color(0xFFE47F26));
      final fill = _parseColor(feature.fillColor, const Color(0xFFFF8656));

      switch (feature.geometryType) {
        case 'LineString':
          final points = _line(feature.coordinates);
          if (points.length < 2) continue;
          polylines.add(
            Polyline(
              points: points,
              strokeWidth: feature.strokeWidth,
              color: border,
            ),
          );
        case 'Polygon':
          final points = _polygonOuter(feature.coordinates);
          if (points.length < 3) continue;
          polygons.add(
            Polygon(
              points: points,
              color: fill.withValues(alpha: feature.fillOpacity),
              borderColor: border,
              borderStrokeWidth: feature.strokeWidth,
            ),
          );
        case 'MultiPolygon':
          final raw = feature.coordinates;
          if (raw is! List) continue;
          for (final polygon in raw) {
            final points = _polygonOuter(polygon);
            if (points.length < 3) continue;
            polygons.add(
              Polygon(
                points: points,
                color: fill.withValues(alpha: feature.fillOpacity),
                borderColor: border,
                borderStrokeWidth: feature.strokeWidth,
              ),
            );
          }
      }
    }

    return MarketMapRenderData(polygons: polygons, polylines: polylines);
  }

  static List<LatLng> _line(dynamic raw) {
    if (raw is! List) return const [];
    return raw.map(_point).whereType<LatLng>().toList(growable: false);
  }

  static List<LatLng> _polygonOuter(dynamic raw) {
    if (raw is! List || raw.isEmpty) return const [];
    return _line(raw.first);
  }

  static LatLng? _point(dynamic raw) {
    if (raw is! List || raw.length < 2) return null;
    final lon = _double(raw[0]);
    final lat = _double(raw[1]);
    if (lat == null || lon == null) return null;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return null;
    return LatLng(lat, lon);
  }

  static double? _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static Color _parseColor(String raw, Color fallback) {
    var value = raw.trim().replaceFirst('#', '');
    if (value.length == 6) value = 'FF$value';
    if (value.length != 8) return fallback;
    final parsed = int.tryParse(value, radix: 16);
    return parsed == null ? fallback : Color(parsed);
  }
}
