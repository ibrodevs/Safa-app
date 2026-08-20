import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/model/market_map_feature.dart';

final class MarketMapRenderData {
  const MarketMapRenderData({
    required this.polygons,
    required this.polylines,
    required this.markers,
    required this.renderedContainerCount,
  });

  final List<Polygon> polygons;
  final List<Polyline> polylines;
  final List<Marker> markers;
  final int renderedContainerCount;

  static const empty = MarketMapRenderData(
    polygons: <Polygon>[],
    polylines: <Polyline>[],
    markers: <Marker>[],
    renderedContainerCount: 0,
  );

  bool get hasRenderedContainers => renderedContainerCount > 0;

  /// Безопасный бюджет контейнеров для мобильного GPU.
  ///
  /// На малом масштабе пользователю важнее видеть базар/районы/проходы, чем
  /// сотни отдельных прямоугольников. При приближении бюджет постепенно
  /// растёт. Порог применяется даже если экран запросил больше объектов.
  static int containerRenderLimitForZoom(double zoom) {
    if (zoom < 15) return 0;
    if (zoom < 16) return 16;
    if (zoom < 17) return 32;
    return 48;
  }

  static int containerLabelLimitForZoom(double zoom) {
    if (zoom < 16) return 0;
    if (zoom < 17) return 12;
    if (zoom < 18) return 24;
    return 36;
  }

  factory MarketMapRenderData.fromFeatures(
    Iterable<MarketMapFeature> features, {
    required double zoom,
    LatLng? center,
    int? maxContainerFeatures,
    bool showLabels = true,
  }) {
    final polygons = <Polygon>[];
    final polylines = <Polyline>[];
    final markers = <Marker>[];
    var renderedContainerCount = 0;
    var renderedContainerLabelCount = 0;
    final containerLabelLimit = containerLabelLimitForZoom(zoom);

    final performanceLimit = containerRenderLimitForZoom(zoom);
    final requestedLimit = maxContainerFeatures;
    final effectiveLimit = requestedLimit == null || requestedLimit < 0
        ? performanceLimit
        : requestedLimit.clamp(0, performanceLimit).toInt();

    final sortedFeatures = _limitContainerFeatures(
      features,
      center: center,
      maxContainerFeatures: effectiveLimit,
    )..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    for (final feature in sortedFeatures) {
      if (_effectiveMinZoom(feature) > zoom) continue;
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
          if (feature.kind == 'container' && zoom >= 16) {
            renderedContainerCount++;
            if (showLabels &&
                renderedContainerLabelCount < containerLabelLimit) {
              renderedContainerLabelCount++;
              markers.add(
                _labelMarker(
                  _boundsCenter(points),
                  feature.name,
                  const Color(0xFF111827),
                ),
              );
            }
          } else if (showLabels &&
              (feature.kind == 'bazar' || feature.kind == 'district')) {
            markers.add(
              _labelMarker(_boundsCenter(points), feature.name, border),
            );
          }
          if (feature.kind == 'container' && zoom < 16) {
            renderedContainerCount++;
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
          if (showLabels && feature.kind == 'passage') {
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
          if (feature.kind == 'container' && zoom >= 16) {
            renderedContainerCount++;
            if (showLabels &&
                renderedContainerLabelCount < containerLabelLimit) {
              renderedContainerLabelCount++;
              markers.add(
                _labelMarker(
                  _boundsCenter(points),
                  feature.name,
                  const Color(0xFF111827),
                ),
              );
            }
          } else if (showLabels &&
              (feature.kind == 'passage' ||
                  feature.kind == 'bazar' ||
                  feature.kind == 'district')) {
            markers.add(
              _labelMarker(_boundsCenter(points), feature.name, border),
            );
          }
          if (feature.kind == 'container' && zoom < 16) {
            renderedContainerCount++;
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
            if (feature.kind == 'container' && zoom >= 16) {
              renderedContainerCount++;
              if (showLabels &&
                  renderedContainerLabelCount < containerLabelLimit) {
                renderedContainerLabelCount++;
                markers.add(
                  _labelMarker(
                    _boundsCenter(points),
                    feature.name,
                    const Color(0xFF111827),
                  ),
                );
              }
            } else if (showLabels &&
                (feature.kind == 'bazar' || feature.kind == 'district')) {
              markers.add(
                _labelMarker(_boundsCenter(points), feature.name, border),
              );
            }
            if (feature.kind == 'container' && zoom < 16) {
              renderedContainerCount++;
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
      renderedContainerCount: renderedContainerCount,
    );
  }

  static int _effectiveMinZoom(MarketMapFeature feature) {
    switch (feature.kind) {
      case 'bazar':
        return feature.minZoom > 10 ? 10 : feature.minZoom;
      case 'district':
        return feature.minZoom > 12 ? 12 : feature.minZoom;
      case 'passage':
        return feature.minZoom > 14 ? 14 : feature.minZoom;
      case 'container':
        return feature.minZoom > 15 ? 15 : feature.minZoom;
      default:
        return feature.minZoom;
    }
  }

  static List<MarketMapFeature> _limitContainerFeatures(
    Iterable<MarketMapFeature> features, {
    required LatLng? center,
    required int? maxContainerFeatures,
  }) {
    final limit = maxContainerFeatures;
    final sorted = features.toList();
    if (limit == null || limit < 0 || center == null) return sorted;
    if (limit == 0) {
      return sorted.where((feature) => !feature.isContainer).toList();
    }

    final containerIndexes = <int>[];
    for (var i = 0; i < sorted.length; i++) {
      if (sorted[i].isContainer) containerIndexes.add(i);
    }
    if (containerIndexes.length <= limit) return sorted;

    final containerDistances =
        containerIndexes
            .map(
              (index) => MapEntry(
                index,
                _featureDistanceSquared(sorted[index], center),
              ),
            )
            .toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    final keepContainers = containerDistances
        .take(limit)
        .map((entry) => entry.key)
        .toSet();
    final output = <MarketMapFeature>[];
    for (var i = 0; i < sorted.length; i++) {
      final feature = sorted[i];
      if (!feature.isContainer || keepContainers.contains(i)) {
        output.add(feature);
      }
    }
    return output;
  }

  static double _featureDistanceSquared(
    MarketMapFeature feature,
    LatLng center,
  ) {
    final lat = feature.centerLat;
    final lon = feature.centerLon;
    if (lat != null && lon != null) {
      final dLat = lat - center.latitude;
      final dLon = lon - center.longitude;
      return dLat * dLat + dLon * dLon;
    }

    final point = _featureCenter(feature.coordinates);
    if (point == null) return double.infinity;
    final dLat = point.latitude - center.latitude;
    final dLon = point.longitude - center.longitude;
    return dLat * dLat + dLon * dLon;
  }

  static LatLng? _featureCenter(dynamic coordinates) {
    final points = <LatLng>[];
    void visit(dynamic raw) {
      if (raw is List && raw.length >= 2) {
        final lon = _double(raw[0]);
        final lat = _double(raw[1]);
        if (lat != null && lon != null) {
          points.add(LatLng(lat, lon));
          return;
        }
      }
      if (raw is List) {
        for (final item in raw) {
          visit(item);
        }
      }
    }

    visit(coordinates);
    if (points.isEmpty) return null;
    return _boundsCenter(points);
  }

  static Marker _labelMarker(LatLng point, String text, Color color) {
    final label = text.trim();
    return Marker(
      point: point,
      width: 72,
      height: 28,
      alignment: Alignment.center,
      child: IgnorePointer(
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, 1),
            child: Text(
              label.isEmpty ? '•' : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
              strutStyle: const StrutStyle(
                fontSize: 11,
                height: 1,
                forceStrutHeight: true,
              ),
              style: TextStyle(
                color: color,
                fontSize: 11,
                height: 1,
                fontWeight: FontWeight.w800,
                shadows: const [Shadow(color: Colors.white, blurRadius: 3)],
              ),
            ),
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
