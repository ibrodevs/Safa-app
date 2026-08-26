import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'
    show LatLngBounds, Polygon, Polyline;
import 'package:latlong2/latlong.dart';
import 'package:yandex_maps_mapkit_lite/mapkit.dart' as ymk;
import 'package:yandex_maps_mapkit_lite/ui_view.dart' as yui;
import 'package:yandex_maps_mapkit_lite/yandex_map.dart';

/// MapKit configuration for the Safa mobile applications.
///
/// The bundled key keeps normal Android builds reproducible. A dart define can
/// still override it for a separate Yandex environment when needed.
abstract final class SafaMapKitConfig {
  static const apiKey = String.fromEnvironment(
    'MAPKIT_API_KEY',
    defaultValue: '49a7f194-1555-4fb0-b929-8db57956ba1d',
  );
  static bool get isConfigured => apiKey.trim().isNotEmpty;
}

/// Backend-authored market geometry is intentionally hidden in the mobile
/// apps. Orders, route stops and live courier markers remain visible.
abstract final class SafaMobileMapFeatures {
  static const backendDrawingLayersEnabled = false;
}

final class SafaMapPosition {
  const SafaMapPosition({required this.center, required this.zoom});

  final LatLng center;
  final double zoom;
}

final class SafaMapMarker {
  const SafaMapMarker({
    required this.id,
    required this.point,
    required this.child,
    this.width = 30,
    this.height = 30,
    this.alignment = Alignment.center,
    this.onTap,
    this.visualKey = '',
    this.zIndex = 30,
  });

  final String id;
  final LatLng point;
  final Widget child;
  final double width;
  final double height;
  final Alignment alignment;
  final VoidCallback? onTap;
  final String visualKey;
  final double zIndex;

  int get renderSignature => Object.hash(
    id,
    point.latitude,
    point.longitude,
    width,
    height,
    alignment.x,
    alignment.y,
    visualKey,
    child.runtimeType,
    zIndex,
  );
}

final class SafaMapController {
  _SafaYandexMapState? _state;
  LatLngBounds? _visibleBounds;

  LatLngBounds? get visibleBounds => _visibleBounds;

  void move(LatLng center, double zoom) => _state?._move(center, zoom);

  void fitBounds(
    LatLngBounds bounds, {
    EdgeInsets padding = EdgeInsets.zero,
    double? maxZoom,
  }) => _state?._fitBounds(bounds, padding: padding, maxZoom: maxZoom);

  void _attach(_SafaYandexMapState state) => _state = state;

  void _detach(_SafaYandexMapState state) {
    if (identical(_state, state)) _state = null;
  }
}

/// Native Yandex MapKit renderer shared by the client, picker and carrier.
///
/// Geometry still uses the app's existing lightweight LatLng/Polygon models,
/// while rendering, camera gestures and map tiles are fully native MapKit.
class SafaYandexMap extends StatefulWidget {
  const SafaYandexMap({
    super.key,
    required this.controller,
    required this.initialCenter,
    this.initialZoom = 15,
    this.polygons = const [],
    this.polylines = const [],
    this.markers = const [],
    this.onMapReady,
    this.onTap,
    this.onPositionChanged,
  });

  final SafaMapController controller;
  final LatLng initialCenter;
  final double initialZoom;
  final List<Polygon> polygons;
  final List<Polyline> polylines;
  final List<SafaMapMarker> markers;
  final VoidCallback? onMapReady;
  final ValueChanged<LatLng>? onTap;
  final void Function(SafaMapPosition position, bool hasGesture)?
  onPositionChanged;

  @override
  State<SafaYandexMap> createState() => _SafaYandexMapState();
}

class _SafaYandexMapState extends State<SafaYandexMap> {
  ymk.MapWindow? _window;
  late final _CameraListener _cameraListener;
  late final _MapTapListener _mapTapListener;
  final List<_MarkerTapListener> _tapListeners = [];
  final List<yui.ViewProvider> _viewProviders = [];
  int _renderSignature = 0;

  @override
  void initState() {
    super.initState();
    _cameraListener = _CameraListener(_onCameraChanged);
    _mapTapListener = _MapTapListener(_onMapTap);
    widget.controller._attach(this);
  }

  @override
  void didUpdateWidget(covariant SafaYandexMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller._detach(this);
      widget.controller._attach(this);
    }
    _syncObjectsIfNeeded();
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    final map = _window?.map;
    if (map != null && map.isValid()) {
      map.removeCameraListener(_cameraListener);
      map.removeInputListener(_mapTapListener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!SafaMapKitConfig.isConfigured) {
      return const ColoredBox(
        color: Color(0xFFF2F4F7),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Карта не настроена. Добавьте MAPKIT_API_KEY при сборке.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return YandexMap(onMapCreated: _onMapCreated);
  }

  void _onMapCreated(ymk.MapWindow window) {
    _window = window;
    final map = window.map;
    window.setMaxFps(30);
    map
      ..mapType = ymk.MapType.VectorMap
      ..rotateGesturesEnabled = false
      ..tiltGesturesEnabled = false
      ..fastTapEnabled = true
      ..indoorEnabled = false
      ..awesomeModelsEnabled = false
      ..hdModeEnabled = false
      ..poiLimit = 100
      ..addCameraListener(_cameraListener)
      ..addInputListener(_mapTapListener);
    _move(widget.initialCenter, widget.initialZoom, animate: false);
    _renderSignature = 0;
    _syncObjectsIfNeeded(force: true);
    _updateVisibleBounds();
    widget.onMapReady?.call();
  }

  void _onMapTap(ymk.Point point) {
    widget.onTap?.call(LatLng(point.latitude, point.longitude));
  }

  void _move(LatLng center, double zoom, {bool animate = true}) {
    final map = _window?.map;
    if (map == null || !map.isValid()) return;
    map.move(
      ymk.CameraPosition(
        _point(center),
        zoom: zoom.clamp(2, 21).toDouble(),
        azimuth: 0,
        tilt: 0,
      ),
      animation: animate
          ? const ymk.Animation(type: ymk.AnimationType.Smooth, duration: 0.25)
          : null,
    );
  }

  void _fitBounds(
    LatLngBounds bounds, {
    required EdgeInsets padding,
    double? maxZoom,
  }) {
    final window = _window;
    if (window == null || !window.isValid()) return;
    final scale = window.scaleFactor;
    final width = window.width().toDouble();
    final height = window.height().toDouble();
    final left = (padding.left * scale).clamp(0, width);
    final top = (padding.top * scale).clamp(0, height);
    final right = (width - padding.right * scale).clamp(left, width);
    final bottom = (height - padding.bottom * scale).clamp(top, height);
    final focusRect = right > left && bottom > top
        ? ymk.ScreenRect(
            ymk.ScreenPoint(x: left.toDouble(), y: top.toDouble()),
            ymk.ScreenPoint(x: right.toDouble(), y: bottom.toDouble()),
          )
        : null;
    var position = window.map.cameraPositionForGeometry(
      ymk.Geometry.fromBoundingBox(
        ymk.BoundingBox(
          ymk.Point(latitude: bounds.south, longitude: bounds.west),
          ymk.Point(latitude: bounds.north, longitude: bounds.east),
        ),
      ),
      focusRect: focusRect,
      azimuth: 0,
      tilt: 0,
    );
    if (maxZoom != null && position.zoom > maxZoom) {
      position = ymk.CameraPosition(
        position.target,
        zoom: maxZoom,
        azimuth: 0,
        tilt: 0,
      );
    }
    window.map.move(
      position,
      animation: const ymk.Animation(
        type: ymk.AnimationType.Smooth,
        duration: 0.3,
      ),
    );
  }

  void _onCameraChanged(
    ymk.CameraPosition camera,
    ymk.CameraUpdateReason reason,
    bool finished,
  ) {
    // `visibleRegion` is comparatively expensive on weak devices. Bounds are
    // consumed only after the gesture settles, so do not recalculate them on
    // every animation frame while the user pinches the map.
    if (finished) _updateVisibleBounds();
    widget.onPositionChanged?.call(
      SafaMapPosition(
        center: LatLng(camera.target.latitude, camera.target.longitude),
        zoom: camera.zoom,
      ),
      reason == ymk.CameraUpdateReason.Gestures,
    );
  }

  void _updateVisibleBounds() {
    final map = _window?.map;
    if (map == null || !map.isValid()) return;
    final region = map.visibleRegion;
    final points = [
      region.topLeft,
      region.topRight,
      region.bottomLeft,
      region.bottomRight,
    ].map((point) => LatLng(point.latitude, point.longitude)).toList();
    widget.controller._visibleBounds = LatLngBounds.fromPoints(points);
  }

  int _pointsSignature(Iterable<LatLng> points) {
    var hash = 17;
    for (final point in points) {
      hash = Object.hash(
        hash,
        (point.latitude * 1000000).round(),
        (point.longitude * 1000000).round(),
      );
    }
    return hash;
  }

  int _polygonSignature(Polygon polygon) => Object.hash(
    _pointsSignature(polygon.points),
    Object.hashAll(
      (polygon.holePointsList ?? const <List<LatLng>>[]).map(_pointsSignature),
    ),
    polygon.color,
    polygon.borderColor,
    polygon.borderStrokeWidth,
  );

  int _polylineSignature(Polyline line) => Object.hash(
    _pointsSignature(line.points),
    line.color,
    line.strokeWidth,
    line.borderColor,
    line.borderStrokeWidth,
  );

  int _calculateRenderSignature() => Object.hash(
    Object.hashAll(widget.polygons.map(_polygonSignature)),
    Object.hashAll(widget.polylines.map(_polylineSignature)),
    Object.hashAll(widget.markers.map((marker) => marker.renderSignature)),
  );

  void _syncObjectsIfNeeded({bool force = false}) {
    final signature = _calculateRenderSignature();
    if (!force && signature == _renderSignature) return;
    _renderSignature = signature;
    final map = _window?.map;
    if (map == null || !map.isValid()) return;

    final collection = map.mapObjects..clear();
    _tapListeners.clear();
    _viewProviders.clear();

    for (var index = 0; index < widget.polygons.length; index += 1) {
      final polygon = widget.polygons[index];
      if (polygon.points.length < 3) continue;
      final outer = _closedRing(polygon.points);
      final holes = (polygon.holePointsList ?? const <List<LatLng>>[])
          .where((ring) => ring.length >= 3)
          .map((ring) => ymk.LinearRing(_closedRing(ring)))
          .toList();
      final object = collection.addPolygon(
        ymk.Polygon(ymk.LinearRing(outer), holes),
      );
      object
        ..strokeColor = polygon.borderColor
        ..strokeWidth = polygon.borderStrokeWidth
        ..fillColor = polygon.color ?? Colors.transparent
        ..zIndex = 10 + index / 1000;
    }

    for (var index = 0; index < widget.polylines.length; index += 1) {
      final line = widget.polylines[index];
      if (line.points.length < 2) continue;
      final object = collection.addPolylineWithGeometry(
        ymk.Polyline(line.points.map(_point).toList()),
      );
      object
        ..style = ymk.LineStyle(
          strokeWidth: line.strokeWidth,
          outlineColor: line.borderColor,
          outlineWidth: line.borderStrokeWidth,
          turnRadius: 6,
        )
        ..setStrokeColor(line.color)
        ..zIndex = 20 + index / 1000;
    }

    for (final marker in widget.markers) {
      final provider = yui.ViewProvider(
        id: 'safa-${Object.hash(marker.id, marker.visualKey, marker.width, marker.height)}',
        cacheable: true,
        builder: () => SizedBox(
          width: marker.width,
          height: marker.height,
          child: marker.child,
        ),
      );
      _viewProviders.add(provider);
      final alignment = marker.alignment;
      final object = collection.addPlacemarkWithViewStyle(
        _point(marker.point),
        provider,
        ymk.IconStyle(
          anchor: math.Point<double>(
            ((1 - alignment.x) / 2).clamp(0, 1).toDouble(),
            ((1 - alignment.y) / 2).clamp(0, 1).toDouble(),
          ),
          flat: false,
          scale: 1,
        ),
      )..zIndex = marker.zIndex;
      final onTap = marker.onTap;
      if (onTap != null) {
        final listener = _MarkerTapListener(onTap);
        _tapListeners.add(listener);
        object.addTapListener(listener);
      }
    }
  }

  static ymk.Point _point(LatLng point) =>
      ymk.Point(latitude: point.latitude, longitude: point.longitude);

  static List<ymk.Point> _closedRing(List<LatLng> points) {
    final output = points.map(_point).toList();
    if (output.isNotEmpty && output.first != output.last) {
      output.add(output.first);
    }
    return output;
  }
}

final class _CameraListener implements ymk.MapCameraListener {
  const _CameraListener(this.callback);

  final void Function(
    ymk.CameraPosition camera,
    ymk.CameraUpdateReason reason,
    bool finished,
  )
  callback;

  @override
  void onCameraPositionChanged(
    ymk.Map map,
    ymk.CameraPosition cameraPosition,
    ymk.CameraUpdateReason cameraUpdateReason,
    bool finished,
  ) => callback(cameraPosition, cameraUpdateReason, finished);
}

final class _MarkerTapListener implements ymk.MapObjectTapListener {
  const _MarkerTapListener(this.onTap);

  final VoidCallback onTap;

  @override
  bool onMapObjectTap(ymk.MapObject mapObject, ymk.Point point) {
    onTap();
    return true;
  }
}

final class _MapTapListener implements ymk.MapInputListener {
  const _MapTapListener(this.onTap);

  final ValueChanged<ymk.Point> onTap;

  @override
  void onMapTap(ymk.Map map, ymk.Point point) => onTap(point);

  @override
  void onMapLongTap(ymk.Map map, ymk.Point point) => onTap(point);
}
