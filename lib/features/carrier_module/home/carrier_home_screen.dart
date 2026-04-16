import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:dogo/core/utils/app_colors.dart';
import 'package:dogo/features/carrier_module/home/view/comp/empty_orders_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/network/api_service.dart';
import '../../../data/network/model/api_exeptions_model.dart';
import '../../../data/notifications/service/push_service.dart';
import 'data/model/nearby_shipment.dart';

enum ShipmentStatus {
  pending,
  assigned,
  inTransit,
  completed,
  canceled,
  unknown,
}

ShipmentStatus parseShipmentStatus(String raw) {
  switch (raw.toLowerCase()) {
    case 'pending':
      return ShipmentStatus.pending;
    case 'assigned':
      return ShipmentStatus.assigned;
    case 'in_transit':
      return ShipmentStatus.inTransit;
    case 'completed':
      return ShipmentStatus.completed;
    case 'canceled':
    case 'cancelled':
      return ShipmentStatus.canceled;
    default:
      return ShipmentStatus.unknown;
  }
}

class CarrierHomeScreen extends StatefulWidget {
  const CarrierHomeScreen({super.key});

  @override
  State<CarrierHomeScreen> createState() => _CarrierHomeScreenState();
}

class _CarrierHomeScreenState extends State<CarrierHomeScreen> {
  static const _accent = Color(0xFFFF8A00);

  final LatLng _bishkekCenter = const LatLng(42.8746, 74.6122);
  final MapController _mapController = MapController();

  double _myLat = 42.8746;
  double _myLon = 74.6122;
  double _centerLat = 42.8746;
  double _centerLon = 74.6122;

  StreamSubscription<Position>? _posSub;

  bool _loadingOnline = false;
  bool _showWelcome = true;

  List<NearbyShipment> _nearby = const [];
  int _nearbyIndex = 0;

  NearbyShipment? get _currentNearby =>
      (_nearby.isNotEmpty && _nearbyIndex >= 0 && _nearbyIndex < _nearby.length)
      ? _nearby[_nearbyIndex]
      : null;

  int? _activeId;
  String _activePublicCode = '';
  ShipmentStatus _activeStatus = ShipmentStatus.unknown;

  int _activeCurrentStopIndex = 0;
  List<_StopUi> _activeStops = const [];
  int _activeFare = 0;

  Timer? _pollTimer;

  bool _routing = false;
  bool _didFitOnce = false;
  String? _routeSignature;
  List<LatLng> _routePoints = const [];

  bool get _hasActive => _activeId != null;
  bool _showEmptyOrders = false;
  Timer? _nearbyPollTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      PushService.instance.registerOnServerOnce(kind: 'carrier');
    });
    _initLocation();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _nearbyPollTimer?.cancel();
    _posSub?.cancel();
    super.dispose();
  }


  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _moveMap(_bishkekCenter);
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _moveMap(_bishkekCenter);
        return;
      }
      if (perm != LocationPermission.always &&
          perm != LocationPermission.whileInUse) {
        _moveMap(_bishkekCenter);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;

      setState(() {
        _myLat = pos.latitude;
        _myLon = pos.longitude;
        _centerLat = _myLat;
        _centerLon = _myLon;
      });
      _moveMap(LatLng(_myLat, _myLon), zoom: 15);

      _posSub?.cancel();
      _posSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen((p) {
            _myLat = p.latitude;
            _myLon = p.longitude;
            if (mounted) setState(() {});
          });
    } catch (_) {
      if (!mounted) return;
      _moveMap(_bishkekCenter);
    }
  }

  void _moveMap(LatLng center, {double zoom = 15}) {
    try {
      _mapController.move(center, zoom);
    } catch (_) {}
  }

  Future<Position> _getCurrentPositionOrThrow() async {
    final ok = await _ensureLocationPermission();
    if (!ok) {
      throw ApiException(
        'Нужен доступ к геолокации, чтобы показать ближайшие заказы',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Некорректный формат ответа сервера');
  }

  Future<Map<String, dynamic>> _getShipmentByIdRaw(int id) async {
    final resp = await ApiService.instance.dio.get('delivery/shipments/$id/');
    return _asMap(resp.data);
  }

  Future<Map<String, dynamic>> _acceptRaw(int id) async {
    final resp = await ApiService.instance.dio.post(
      'delivery/shipments/$id/accept/',
    );
    return _asMap(resp.data);
  }

  Future<Map<String, dynamic>> _advanceRaw(int id) async {
    final resp = await ApiService.instance.dio.post(
      'delivery/shipments/$id/advance/',
    );
    return _asMap(resp.data);
  }

  _ActiveUi _parseActive(Map<String, dynamic> j, {int? fallbackIndex}) {
    final id = (j['id'] as num?)?.toInt() ?? 0;
    final statusRaw = (j['status'] ?? '').toString();
    final status = parseShipmentStatus(statusRaw);
    final publicCode = (j['public_code'] ?? '').toString();
    final fare = (j['estimated_fare'] as num?)?.toInt() ?? 0;

    int? idx;
    final a = j['current_stop_index'];
    if (a is int) idx = a;
    if (a is num) idx = a.toInt();

    if (idx == null) {
      final b = j['current_stop'];
      if (b is Map) {
        final m = Map<String, dynamic>.from(b);
        final v = m['index'] ?? m['position'];
        if (v is int) idx = v;
        if (v is num) idx = v.toInt();
      }
    }

    idx ??= fallbackIndex ?? 0;

    final stops = <_StopUi>[];
    final rawStops = j['stops'];
    if (rawStops is List) {
      for (final s in rawStops) {
        if (s is! Map) continue;
        stops.add(_StopUi.fromJson(Map<String, dynamic>.from(s)));
      }
    }

    if (stops.isNotEmpty) {
      idx = idx.clamp(0, stops.length - 1);
    } else {
      idx = 0;
    }
    return _ActiveUi(
      id: id,
      publicCode: publicCode,
      status: status,
      currentStopIndex: idx,
      stops: stops,
      fare: fare,
    );
  }
  Future<void> _refreshNearbySilently() async {
    if (_hasActive) return;
    try {
      final ok = await _ensureLocationPermission();
      if (!ok) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final page = await ApiService.instance.getNearbyShipments(
        lat: pos.latitude,
        lon: pos.longitude,
      );

      if (!mounted) return;

      if (page.results.isEmpty) {
        return;
      }

      setState(() {
        _showEmptyOrders = false;
        _showWelcome = false;

        _nearby = page.results;
        _nearbyIndex = 0;

        _myLat = pos.latitude;
        _myLon = pos.longitude;
        _centerLat = _myLat;
        _centerLon = _myLon;

        _didFitOnce = false;
        _routeSignature = null;
        _routePoints = const [];
      });

      await _syncRouteAndCameraForNearby();
    } catch (_) {

    }
  }

  Future<void> _goOnline() async {
    if (_loadingOnline) return;
    setState(() => _loadingOnline = true);

    try {
      final pos = await _getCurrentPositionOrThrow();

      final page = await ApiService.instance.getNearbyShipments(
        lat: pos.latitude,
        lon: pos.longitude,
      );

      if (!mounted) return;

      if (page.results.isEmpty) {
        if (!mounted) return;
        setState(() {
          _nearby = const [];
          _nearbyIndex = 0;

          _showWelcome = false;
          _showEmptyOrders = true;
        });
        _startNearbyPolling();
        return;
      }


      setState(() {
        _showWelcome = false;
        _nearby = page.results;
        _nearbyIndex = 0;

        _myLat = pos.latitude;
        _myLon = pos.longitude;
        _centerLat = _myLat;
        _centerLon = _myLon;
        _stopNearbyPolling();

        _didFitOnce = false;
        _routeSignature = null;
        _routePoints = const [];
      });

      await _syncRouteAndCameraForNearby();
    } catch (e) {
      if (!mounted) return;

      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Разрешите геолокацию в настройках приложения'),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Произошла ошибка')));
      }
    } finally {
      if (mounted) setState(() => _loadingOnline = false);
    }
  }

  void _rejectNearby() {
    if (_nearby.isEmpty) return;
    setState(() {
      _nearbyIndex++;
      if (_nearbyIndex >= _nearby.length) _nearbyIndex = 0;
      _didFitOnce = false;
      _routeSignature = null;
      _routePoints = const [];
    });
    _syncRouteAndCameraForNearby();
  }

  Future<void> _acceptCurrent() async {
    final s = _currentNearby;
    if (s == null) return;
    try {
      final raw = await _acceptRaw(s.id);
      final parsed = _parseActive(raw, fallbackIndex: 0);

      if (!mounted) return;

      setState(() {
        _activeId = parsed.id;
        _activePublicCode = parsed.publicCode;
        _activeStatus = parsed.status;
        _activeCurrentStopIndex = parsed.currentStopIndex;
        _activeStops = parsed.stops;
        _activeFare = parsed.fare;
        _nearby = const [];
        _nearbyIndex = 0;
        _stopNearbyPolling();
        _didFitOnce = false;
        _routeSignature = null;
        _routePoints = const [];
      });
      _startPolling(parsed.id);
      await _syncRouteAndCameraForActive();
    } catch (e) {
      if (!mounted) return;
    }
  }

  void _startPolling(int id) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll(id));
    _poll(id);
  }

  Future<void> _poll(int id) async {
    try {
      final raw = await _getShipmentByIdRaw(id);
      if (!mounted) return;

      final parsed = _parseActive(raw, fallbackIndex: _activeCurrentStopIndex);

      setState(() {
        _activeStatus = parsed.status;
        _activeCurrentStopIndex = parsed.currentStopIndex;
        _activeStops = parsed.stops;
        _activePublicCode = parsed.publicCode;
        _activeFare = parsed.fare;
      });
      if (parsed.status == ShipmentStatus.canceled) {
        _stopActiveAndBackToWelcome(message: 'Заказ отменён');
        return;
      }
      await _syncRouteAndCameraForActive();
    } catch (_) {}
  }
  void _startNearbyPolling() {
    _nearbyPollTimer?.cancel();
    _nearbyPollTimer = Timer.periodic(
      const Duration(seconds: 7),
          (_) => _refreshNearbySilently(),
    );
    _refreshNearbySilently();
  }

  void _stopNearbyPolling() {
    _nearbyPollTimer?.cancel();
    _nearbyPollTimer = null;
  }

  void _stopActiveAndBackToWelcome({String? message}) {
    _pollTimer?.cancel();
    _pollTimer = null;

    setState(() {
      _activeId = null;
      _activePublicCode = '';
      _activeStatus = ShipmentStatus.unknown;
      _activeCurrentStopIndex = 0;
      _activeStops = const [];
      _activeFare = 0;

      _showWelcome = true;

      _didFitOnce = false;
      _routeSignature = null;
      _routePoints = const [];
    });

    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Произошла ошибка')));
    }
  }

  Future<void> _advance() async {
    final id = _activeId;
    if (id == null) return;

    try {
      final raw = await _advanceRaw(id);
      final parsed = _parseActive(
        raw,
        fallbackIndex: _activeCurrentStopIndex + 1,
      );

      if (!mounted) return;

      setState(() {
        _activeStatus = parsed.status;
        _activeCurrentStopIndex = parsed.currentStopIndex;
        _activeStops = parsed.stops;
        _activePublicCode = parsed.publicCode;
        _activeFare = parsed.fare;

        _didFitOnce = false;
        _routeSignature = null;
        _routePoints = const [];
      });

      await _syncRouteAndCameraForActive();

      if (parsed.status == ShipmentStatus.completed) {}
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Произошла ошибка')));
    }
  }

  List<LatLng> _pointsFromStops(List<_StopUi> stops) {
    final out = <LatLng>[];
    for (final s in stops) {
      final lat = s.lat;
      final lon = s.lon;
      if (lat == null || lon == null) continue;
      if (!lat.isFinite || !lon.isFinite) continue;
      if (lat < -90 || lat > 90 || lon < -180 || lon > 180) continue;
      out.add(LatLng(lat, lon));
    }
    return out;
  }

  String _signature(List<LatLng> pts) {
    String f(double v) => v.toStringAsFixed(6);
    return pts.map((p) => '${f(p.latitude)},${f(p.longitude)}').join('|');
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.denied) {
      return false;
    }

    if (perm == LocationPermission.deniedForever) {
      return false;
    }

    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<List<LatLng>> _buildOsrmLegRoute({
    required LatLng a,
    required LatLng b,
  }) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    const profiles = <String>['foot', 'walking', 'driving'];
    final coords = '${a.longitude},${a.latitude};${b.longitude},${b.latitude}';

    for (final profile in profiles) {
      try {
        final resp = await dio.get(
          'https://router.project-osrm.org/route/v1/$profile/$coords',
          queryParameters: {
            'overview': 'full',
            'geometries': 'geojson',
            'steps': 'false',
          },
        );

        final data = resp.data;
        final routes = (data is Map) ? data['routes'] : null;
        if (routes is! List || routes.isEmpty) continue;

        final geom = routes.first['geometry'];
        final coordsList = (geom is Map) ? geom['coordinates'] : null;
        if (coordsList is! List) continue;

        final out = <LatLng>[];
        for (final c in coordsList) {
          if (c is! List || c.length < 2) continue;
          final lon = (c[0] as num).toDouble();
          final lat = (c[1] as num).toDouble();
          out.add(LatLng(lat, lon));
        }
        if (out.isNotEmpty) return out;
      } catch (_) {}
    }

    return const [];
  }

  Future<List<LatLng>> _buildOsrmRouteMultiLeg(List<LatLng> pts) async {
    if (pts.length < 2) return const [];
    final full = <LatLng>[];

    for (int i = 0; i < pts.length - 1; i++) {
      final leg = await _buildOsrmLegRoute(a: pts[i], b: pts[i + 1]);

      if (leg.isEmpty) {
        if (full.isNotEmpty) full.add(pts[i]);
        full.add(pts[i + 1]);
      } else {
        if (full.isNotEmpty) {
          full.addAll(leg.skip(1));
        } else {
          full.addAll(leg);
        }
      }

      if (i != pts.length - 2) {
        await Future.delayed(const Duration(milliseconds: 1100));
      }
    }

    return full;
  }

  void _fitToPoints(List<LatLng> pts) {
    if (pts.isEmpty) return;

    final clean = pts.where((p) {
      final lat = p.latitude;
      final lon = p.longitude;
      return lat.isFinite &&
          lon.isFinite &&
          lat >= -90 &&
          lat <= 90 &&
          lon >= -180 &&
          lon <= 180;
    }).toList();

    if (clean.isEmpty) return;

    if (clean.length == 1) {
      _mapController.move(clean.first, 15);
      return;
    }

    final bounds = LatLngBounds.fromPoints(clean);

    const eps = 1e-6;
    final degenerate =
        (bounds.north - bounds.south).abs() < eps &&
        (bounds.east - bounds.west).abs() < eps;

    if (degenerate) {
      _mapController.move(clean.first, 15);
      return;
    }

    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final padding = EdgeInsets.fromLTRB(36, 90, 36, 320 + bottomSafe);

    try {
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: padding, maxZoom: 17),
      );
    } catch (_) {
      _mapController.move(clean.first, 15);
    }
  }

  Future<void> _syncRouteAndCameraForNearby() async {
    final s = _currentNearby;
    if (s == null) return;

    final pts = _pointsFromStops(
      s.stops.map((e) => _StopUi.fromNearby(e)).toList(),
    );

    await _syncRouteAndCameraCommon(pts);
  }

  Future<void> _syncRouteAndCameraForActive() async {
    final pts = _pointsFromStops(_activeStops);
    await _syncRouteAndCameraCommon(pts);
  }

  Future<void> _syncRouteAndCameraCommon(List<LatLng> pts) async {
    if (!mounted) return;

    if (!_didFitOnce && pts.isNotEmpty) {
      _didFitOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fitToPoints(pts);
      });
    }

    if (pts.length < 2) {
      if (_routePoints.isNotEmpty) setState(() => _routePoints = const []);
      return;
    }

    final sig = _signature(pts);
    if (_routeSignature == sig) return;
    if (_routing) return;
    _routing = true;

    try {
      final route = await _buildOsrmRouteMultiLeg(pts);
      if (!mounted) return;

      setState(() {
        _routeSignature = sig;
        _routePoints = route.isNotEmpty ? route : pts;
      });
    } finally {
      _routing = false;
    }
  }

  int _distanceToCurrentStopMeters() {
    if (!_hasActive || _activeStops.isEmpty) return 0;
    final i = _activeCurrentStopIndex.clamp(0, _activeStops.length - 1);
    final s = _activeStops[i];
    if (s.lat == null || s.lon == null) return 0;

    final d = Geolocator.distanceBetween(_myLat, _myLon, s.lat!, s.lon!);
    return d.round();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final padding = MediaQuery.viewPaddingOf(context);
    final bottomSafe = padding.bottom;

    final markers = <Marker>[];

    final stopPts = <LatLng>[];
    if (_hasActive) {
      for (final s in _activeStops) {
        if (s.lat == null || s.lon == null) continue;
        stopPts.add(LatLng(s.lat!, s.lon!));
      }
    } else {
      final s = _currentNearby;
      if (s != null) {
        for (final st in s.stops) {
          stopPts.add(LatLng(st.lat, st.lon));
        }
      }
    }

    for (final p in stopPts) {
      markers.add(
        Marker(
          point: p,
          width: 26,
          height: 26,
          alignment: Alignment.center,
          child: const _StopDot(),
        ),
      );
    }

    Widget bottom;
    if (_showWelcome) {
      bottom = _WelcomeCard(loading: _loadingOnline, onTap: _goOnline);
    } else if (!_hasActive && _currentNearby != null) {
      bottom = _ShipmentSheet(
        shipment: _currentNearby!,
        accent: _accent,
        routeLoading: _routing,
        onAccept: _acceptCurrent,
        onReject: _rejectNearby,
      );
    } else if (_hasActive) {
      if (_activeStatus == ShipmentStatus.completed) {
        bottom = _CompletedSheet(
          publicCode: _activePublicCode,
          fare: _activeFare,
          accent: _accent,
          onDone: () => _stopActiveAndBackToWelcome(),
          stops: _activeStops,
        );
      } else {
        final dist = _distanceToCurrentStopMeters();
        bottom = _ActiveProgressSheet(
          accent: _accent,
          status: _activeStatus,
          publicCode: _activePublicCode,
          distanceM: dist,
          stops: _activeStops,
          currentIndex: _activeCurrentStopIndex,
          onAdvance: _advance,
        );
      }
    } else {
      bottom = const SizedBox.shrink();
    }
    if (_showEmptyOrders && !_hasActive) {
      return const EmptyOrdersScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_centerLat, _centerLon),
              initialZoom: 15,
              onPositionChanged: (pos, hasGesture) {
                _centerLat = pos.center.latitude;
                _centerLon = pos.center.longitude;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'kg.genesis.dogo',
              ),

              if (_routePoints.isNotEmpty) ...[
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5,
                      color: Colors.black.withValues(alpha: 0.75),
                    ),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ],
                ),
              ],
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.08),
                      Colors.black.withValues(alpha: 0.16),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                0,
                12,
                bottomSafe + viewInsets.bottom + 12,
              ),
              child: bottom,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopDot extends StatelessWidget {
  const _StopDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFFF6D9C8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Рады вас видеть',
                style: TextStyle(
                  fontSize: 26,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Сатурн — шестая планета по удалённости от \nСолнца и вторая по размерам планета',
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: -0.4,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: AppColors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A00),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    loading ? 'Загружаем…' : 'На линию',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShipmentSheet extends StatelessWidget {
  const _ShipmentSheet({
    required this.shipment,
    required this.accent,
    required this.routeLoading,
    required this.onAccept,
    required this.onReject,
  });

  final NearbyShipment shipment;
  final Color accent;
  final bool routeLoading;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final distance = shipment.distanceM;
    final distanceText = distance >= 1000
        ? '${(distance / 1000).toStringAsFixed(1)} км'
        : '$distance метров';

    final stopsCount = shipment.stops.length;
    final sigment = shipment.segment?.name;
    final nearestHint = shipment.stops.isNotEmpty
        ? shipment.stops.first.shortHint
        : '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$distanceText от вас',
            style: const TextStyle(
              fontSize: 22,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            nearestHint.isNotEmpty
                ? 'Ближайшая подача: $nearestHint'
                : 'Ближайшая подача',
            style: const TextStyle(
              fontSize: 15,
              height: 1.25,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9FA4AD),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _Chip(
                  icon: 'assets/icons/ic_box.svg',
                  label: '$sigment',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _Chip(
                  icon: 'assets/icons/ic_map.svg',
                  label: '$stopsCount точки',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                '${shipment.estimatedFare} сом',
                style: const TextStyle(
                  fontSize: 22,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),

              const Spacer(),

              SvgPicture.asset('assets/icons/ic_add_raiting.svg'),
              const SizedBox(width: 2),
              const Text(
                '+1 рейтинг',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF22C55E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (routeLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Забрать заказ',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Отказать',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveProgressSheet extends StatelessWidget {
  const _ActiveProgressSheet({
    required this.accent,
    required this.status,
    required this.publicCode,
    required this.distanceM,
    required this.stops,
    required this.currentIndex,
    required this.onAdvance,
  });

  final Color accent;
  final ShipmentStatus status;
  final String publicCode;
  final int distanceM;
  final List<_StopUi> stops;
  final int currentIndex;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final distanceText = distanceM >= 1000
        ? '${(distanceM / 1000).toStringAsFixed(1)} км'
        : '$distanceM метров';

    final isLast = stops.isNotEmpty && currentIndex >= stops.length - 1;
    final ci = stops.isEmpty ? 0 : currentIndex.clamp(0, stops.length - 1);
    final showTwoStops = (ci == 0 && stops.length >= 2);

    final buttonText =
    (status == ShipmentStatus.assigned || showTwoStops)
        ? 'Начать'
        : (isLast ? 'Выполнено' : 'Следующая точка');


    final items = <_StopUi>[];
    if (stops.isNotEmpty) {
      final ci = currentIndex.clamp(0, stops.length - 1);
      if (ci - 1 >= 0) items.add(stops[ci - 1]);
      items.add(stops[ci]);
      if (ci + 1 < stops.length && items.length < 2) items.add(stops[ci + 1]);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status == ShipmentStatus.assigned) ...[
            Text(
              '$distanceText от вас',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (stops.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 18,
                      width: 16,
                      child: SvgPicture.asset(
                        'assets/icons/ic_map.svg',
                        colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        stops.first.shortLine,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 8),
            const Center(
              child: Text(
                'Сатурн — шестая планета по удалённости от Солнца и вторая по размерам планета',
                style: TextStyle(
                  fontSize: 15,
                  letterSpacing: -0.4,
                  height: 1.3,
                  fontFamily: 'SFProDisplay',
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            if (stops.isNotEmpty) ...[
              Builder(
                builder: (_) {
                  final ci = currentIndex.clamp(0, stops.length - 1);
                  final showTwoStops = (ci == 0 && stops.length >= 2);
                  if (showTwoStops) {
                    return _TwoStopsCard(
                      items: [stops[0], stops[1]],
                      currentIndex: ci,
                    );
                  }
                  return _ProgressStopsCard(
                    status: status,
                    stops: stops,
                    currentIndex: ci,
                  );
                },
              ),
              const SizedBox(height: 14),
            ],
          ],
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAdvance,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStopsCard extends StatelessWidget {
  const _ProgressStopsCard({
    required this.status,
    required this.stops,
    required this.currentIndex,
  });

  final ShipmentStatus status;
  final List<_StopUi> stops;

  final int currentIndex;

  static const _green = Color(0xFF41C44B);

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();

    if (status == ShipmentStatus.assigned) {
      final first = stops.first;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StopRow(
              title: first.headerLine,
              subtitle: first.subLine,
              trailing: const _TrailingStatus(text: 'Вы здесь', color: _green),
              muted: false,
            ),
          ],
        ),
      );
    }

    final ci = currentIndex.clamp(0, stops.length - 1);
    final cur = stops[ci];

    final hasNext = ci < stops.length - 1;
    final next = hasNext ? stops[ci + 1] : null;

    final hasPrev = ci - 1 >= 0;
    final prev = hasPrev ? stops[ci - 1] : null;

    final label = _pointLabelRu(ci);

    if (next != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StopRow(
              title: cur.headerLine,
              subtitle: cur.subLine,
              trailing: _TrailingHere(title: 'Вы здесь', subtitle: label),
              muted: true,
            ),
            const SizedBox(height: 10),
            const _ArrowDown(),
            const SizedBox(height: 10),
            _StopRow(
              title: next.headerLine,
              subtitle: next.subLine,
              trailing: null,
              muted: false,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prev != null) ...[
            _StopRow(
              title: prev.headerLine,
              subtitle: prev.subLine,
              trailing: null,
              muted: true,
            ),
            const SizedBox(height: 10),
            const _ArrowDown(),
            const SizedBox(height: 10),
          ],
          _StopRow(
            title: cur.headerLine,
            subtitle: cur.subLine,
            trailing: _TrailingHere(title: 'Вы здесь', subtitle: label),
            muted: false,
          ),
        ],
      ),
    );
  }

}

class _TwoStopsCard extends StatelessWidget {
  const _TwoStopsCard({required this.items, required this.currentIndex});

  final List<_StopUi> items;
  final int currentIndex;

  static const _green = Color(0xFF41C44B);
  static const _grey = Color(0xFFB7BCC5);

  @override
  Widget build(BuildContext context) {
    final prev = items.length >= 2 ? items[0] : null;
    final cur = items.isNotEmpty ? items.last : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prev != null)
            _StopRow(
              title: prev.headerLine,
              subtitle: prev.subLine,
              trailing: const _TrailingStatus(
                text: 'Забрали груз',
                color: _grey,
              ),
            ),
          if (prev != null) ...[
            const SizedBox(height: 10),
            const _ArrowDown(),
            const SizedBox(height: 10),
          ],
          if (cur != null)
            _StopRow(
              title: cur.headerLine,
              subtitle: cur.subLine,
              trailing: const _TrailingStatus(text: 'Вы здесь', color: _green),
            ),
        ],
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.muted = false,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    const double trailingW = 130;

    final titleStyle = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: muted ? const Color(0xFFB7BCC5) : Colors.black,
    );

    final subStyle = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: muted ? const Color(0xFFB7BCC5) : const Color(0xFF9AA0A6),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle),
              const SizedBox(height: 4),
              Text(subtitle, style: subStyle),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          SizedBox(width: trailingW, child: trailing),
        ],
      ],
    );
  }
}

String _pointLabelRu(int idx0) {
  final n = idx0 + 1;
  switch (n) {
    case 1:
      return 'Первая точка';
    case 2:
      return 'Вторая точка';
    case 3:
      return 'Третья точка';
    case 4:
      return 'Четвертая точка';
    default:
      return '$n-я точка';
  }
}


class _TrailingHere extends StatelessWidget {
  const _TrailingHere({required this.title, required this.subtitle});

  final String title; // "Вы здесь"
  final String subtitle; // "Третья точка"

  static const _green = Color(0xFF41C44B);
  static const _grey = Color(0xFFB7BCC5);

  @override
  Widget build(BuildContext context) {
    const barW = 2.0;
    const barH = 44.0;

    // ширины под твою верстку (как в _TrailingStatus)
    const width = 130.0;
    const textSlot = 110.0;
    const gap = 10.0;

    final barRight = textSlot + gap;

    return SizedBox(
      width: width,
      height: barH,
      child: Stack(
        children: [
          Positioned(
            right: barRight,
            top: 0,
            bottom: 0,
            child: Container(
              width: barW,
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: textSlot,
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _green,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _grey,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailingStatus extends StatelessWidget {
  const _TrailingStatus({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;
  static const double width = 120;
  static const double textSlot = 100;
  static const double gap = 10;

  @override
  Widget build(BuildContext context) {
    const barW = 2.0;
    const barH = 44.0;

    final barRight = textSlot + gap;

    return SizedBox(
      width: width,
      height: barH,
      child: Stack(
        children: [
          Positioned(
            right: barRight,
            top: 0,
            bottom: 0,
            child: Container(
              width: barW,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: textSlot,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowDown extends StatelessWidget {
  const _ArrowDown();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 6),
        child: SvgPicture.asset('assets/icons/ic_arrow_long.svg'),
      ),
    );
  }
}

class _CompletedSheet extends StatelessWidget {
  const _CompletedSheet({
    required this.publicCode,
    required this.fare,
    required this.accent,
    required this.onDone,
    required this.stops,
  });

  final String publicCode;
  final int fare;
  final Color accent;
  final VoidCallback onDone;

  final List<_StopUi> stops;

  @override
  Widget build(BuildContext context) {
    final orderedStops = stops;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Заказ выполнен',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF43C432),
                  ),
                ),
              ),
              if (publicCode.isNotEmpty)
                Text(
                  '#$publicCode',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9AA0A6),
                  ),
                ),
            ],
          ),

          if (orderedStops.isNotEmpty) ...[
            const SizedBox(height: 10),
            _StopsTimeline(stops: orderedStops),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 12),
          ] else ...[
            const SizedBox(height: 12),
          ],

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  flex: 3,
                  child: _StatCard(
                    big: '+$fare',
                    small: 'Сомов заработано',
                    icon: 'assets/icons/ic_wallet.svg',
                  ),
                ),
                const SizedBox(width: 16),
                const Flexible(
                  flex: 2,
                  child: _StatCard(
                    big: '+1',
                    small: 'К рейтингу',
                    icon: 'assets/icons/ic_rait.svg',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Выполнено',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopsTimeline extends StatelessWidget {
  const _StopsTimeline({required this.stops});

  final List<_StopUi> stops;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.42;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(stops.length, (i) {
        final s = stops[i];
        final isLast = i == stops.length - 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StopTile(stop: s),
            if (!isLast) ...[
              const SizedBox(height: 6),
              Padding(
                padding: EdgeInsets.only(left: 2),
                child: SvgPicture.asset('assets/icons/ic_arrow_long.svg'),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      }),
    );
    if (stops.length <= 4) return content;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(child: content),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({required this.stop});

  final _StopUi stop;

  @override
  Widget build(BuildContext context) {
    final header = stop.headerLine;
    final sub = stop.subLine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            height: 1.15,
          ),
        ),
        if (sub.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9AA0A6),
              height: 1.1,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.big, required this.small, required this.icon});

  final String big;
  final String small;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            big,
            style: const TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: SvgPicture.asset(icon, colorFilter: ColorFilter.mode(AppColors.green, BlendMode.srcIn)),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  small,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.3),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 18,
            width: 16,
            child: SvgPicture.asset(icon, colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopUi {
  final String title;
  final String? bazar;
  final String? passage;
  final String? container;
  final double? lat;
  final double? lon;

  _StopUi({
    required this.title,
    required this.lat,
    required this.lon,
    this.bazar,
    this.passage,
    this.container,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    final d = double.tryParse(v.toString());
    if (d == null || !d.isFinite) return null;
    if (d.abs() > 1e9) return null;
    return d;
  }

  static String? _pickContainer(Map<String, dynamic> json) {
    final a = json['container_number']?.toString();
    if (a != null && a.trim().isNotEmpty) return a.trim();
    final b = json['container_label']?.toString();
    if (b != null && b.trim().isNotEmpty) return b.trim();
    final c = json['container']?.toString();
    if (c != null && c.trim().isNotEmpty) return c.trim();
    return null;
  }

  factory _StopUi.fromJson(Map<String, dynamic> j) {
    return _StopUi(
      title: (j['title'] ?? '').toString(),
      bazar: j['bazar']?.toString(),
      passage: j['passage']?.toString(),
      container: _pickContainer(j),
      lat: _toDouble(j['lat']),
      lon: _toDouble(j['lon']),
    );
  }

  factory _StopUi.fromNearby(NearbyShipmentStop s) {
    return _StopUi(
      title: s.title,
      bazar: s.bazar,
      passage: s.passage,
      container: s.container,
      lat: s.lat,
      lon: s.lon,
    );
  }

  String get headerLine {
    final c = (container ?? '').trim();
    final p = (passage ?? '').trim();
    if (c.isNotEmpty && p.isNotEmpty) return 'Контейнер $c, $p проход';
    if (c.isNotEmpty) return 'Контейнер $c';
    if (p.isNotEmpty) return '$p проход';
    return title.isNotEmpty ? title : 'Точка';
  }

  String get subLine {
    final b = (bazar ?? '').trim();
    return b.isNotEmpty ? b : '';
  }

  String get shortLine {
    final p = (passage ?? '').trim();
    final c = (container ?? '').trim();
    final parts = <String>[];
    if (p.isNotEmpty) parts.add('$p проход');
    if (c.isNotEmpty) parts.add('$c контейнер');
    return parts.join(', ');
  }
}

class _ActiveUi {
  final int id;
  final String publicCode;
  final ShipmentStatus status;
  final int currentStopIndex;
  final List<_StopUi> stops;
  final int fare;

  _ActiveUi({
    required this.id,
    required this.publicCode,
    required this.status,
    required this.currentStopIndex,
    required this.stops,
    required this.fare,
  });
}
