import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/model/market_map_feature.dart';

final class MarketMapRenderData {
  const MarketMapRenderData({
    required this.polygons,
    required this.polylines,
    required this.markers,
  });

  final List<Polygon> polygons;
  final List<Polyline> polylines;
  final List<Marker> markers;

  factory MarketMapRenderData.fromFeatures(
    Iterable<MarketMapFeature> features, {
    required double zoom,
  }) {
    final polygons = <Polygon>[];
    final polylines = <Polyline>[];
    final markers = <Marker>[];

    final sortedFeatures = features.toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    for (final feature in sortedFeatures) {
      if (feature.minZoom > zoom) continue;
      final border = _parseColor(feature.strokeColor, const Color(0xFFE47F26));
      final fill = _parseColor(feature.fillColor, const Color(0xFFFF8656));
      final pattern = feature.linePattern == 'dashed'
          ? StrokePattern.dashed(segments: const [10, 8])
          : const StrokePattern.solid();

      switch (feature.geometryType) {
        case 'Point':
          final point = _point(feature.coordinates);
          if (point == null) continue;
          final points = _pointRectangle(point);
          polygons.add(
            Polygon(
              points: points,
              color: fill.withValues(alpha: feature.fillOpacity),
              borderColor: border,
              borderStrokeWidth: feature.strokeWidth,
            ),
          );
          if (feature.kind == 'container') {
            markers.add(
              _labelMarker(
                _boundsCenter(points),
                feature.name,
                const Color(0xFF111827),
              ),
            );
          }
          break;
        case 'LineString':
          final points = _line(feature.coordinates);
          if (points.length < 2) continue;
          polylines.add(
            Polyline(
              points: points,
              strokeWidth: feature.strokeWidth,
              color: border,
              pattern: pattern,
            ),
          );
          if (feature.kind == 'passage') {
            final center = _boundsCenter(points);
            markers.add(_labelMarker(center, feature.name, border));
          }
          break;
        case 'Polygon':
          final points = _polygonOuter(feature.coordinates);
          if (points.length < 3) continue;
          polygons.add(
            Polygon(
              points: points,
              color: fill.withValues(alpha: feature.fillOpacity),
              borderColor: border,
              borderStrokeWidth: feature.strokeWidth,
              pattern: pattern,
            ),
          );
          if (feature.kind == 'container') {
            markers.add(
              _labelMarker(
                _boundsCenter(points),
                feature.name,
                const Color(0xFF111827),
              ),
            );
          }
          break;
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
                pattern: pattern,
              ),
            );
            if (feature.kind == 'container') {
              markers.add(
                _labelMarker(
                  _boundsCenter(points),
                  feature.name,
                  const Color(0xFF111827),
                ),
              );
            }
          }
          break;
        default:
          break;
      }
    }

    return MarketMapRenderData(
      polygons: polygons,
      polylines: polylines,
      markers: markers,
    );
  }

  static Marker _labelMarker(LatLng point, String text, Color color) {
    return Marker(
      point: point,
      width: 72,
      height: 28,
      alignment: Alignment.center,
      child: IgnorePointer(
        child: Text(
          text.trim().isEmpty ? '•' : text.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 12,
            height: 1,
            fontWeight: FontWeight.w800,
            shadows: const [
              Shadow(color: Colors.white, blurRadius: 3),
              Shadow(color: Colors.white, blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }

  static LatLng _boundsCenter(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLon = points.first.longitude;
    var maxLon = points.first.longitude;
    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }
    return LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);
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

  static List<LatLng> _pointRectangle(LatLng center) {
    const latHalf = 0.000012;
    const lonHalf = 0.000018;
    return [
      LatLng(center.latitude + latHalf, center.longitude - lonHalf),
      LatLng(center.latitude + latHalf, center.longitude + lonHalf),
      LatLng(center.latitude - latHalf, center.longitude + lonHalf),
      LatLng(center.latitude - latHalf, center.longitude - lonHalf),
    ];
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
