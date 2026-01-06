import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/network/api_service.dart';
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
  static const _greyText = Color(0xFF9FA4AD);

  final LatLng _bishkekCenter = const LatLng(42.8746, 74.6122);
  final MapController _mapController = MapController();

  // my location
  double _myLat = 42.8746;
  double _myLon = 74.6122;
  double _centerLat = 42.8746;
  double _centerLon = 74.6122;

  StreamSubscription<Position>? _posSub;

  // UI states
  bool _loadingOnline = false;
  bool _showWelcome = true;

  // nearby flow
  List<NearbyShipment> _nearby = const [];
  int _nearbyIndex = 0;
  NearbyShipment? get _currentNearby =>
      (_nearby.isNotEmpty && _nearbyIndex >= 0 && _nearbyIndex < _nearby.length)
          ? _nearby[_nearbyIndex]
          : null;

  // active shipment after accept
  int? _activeId;
  String _activePublicCode = '';
  ShipmentStatus _activeStatus = ShipmentStatus.unknown;

  int _activeCurrentStopIndex = 0;
  List<_StopUi> _activeStops = const [];
  int _activeFare = 0;

  Timer? _pollTimer;

  // routing
  bool _routing = false;
  bool _didFitOnce = false;
  String? _routeSignature;
  List<LatLng> _routePoints = const [];

  bool get _hasActive => _activeId != null;

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
    _posSub?.cancel();
    super.dispose();
  }

  // ---------------------------
  // LOCATION
  // ---------------------------
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
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;

      setState(() {
        _myLat = pos.latitude;
        _myLon = pos.longitude;
        _centerLat = _myLat;
        _centerLon = _myLon;
      });
      _moveMap(LatLng(_myLat, _myLon), zoom: 15);

      // лёгкий стрим, чтобы обновлять дистанцию/маркер (можно убрать)
      _posSub?.cancel();
      _posSub = Geolocator.getPositionStream(
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
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Службы геолокации выключены');

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Нет доступа к геолокации');
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  // ---------------------------
  // API (RAW MAP) helpers
  // ---------------------------
  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Некорректный формат ответа сервера');
  }

  Future<Map<String, dynamic>> _getShipmentByIdRaw(int id) async {
    final resp = await ApiService.instance.dio.get('delivery/shipments/$id/');
    return _asMap(resp.data);
  }

  Future<Map<String, dynamic>> _acceptRaw(int id) async {
    final resp =
    await ApiService.instance.dio.post('delivery/shipments/$id/accept/');
    return _asMap(resp.data);
  }

  Future<Map<String, dynamic>> _advanceRaw(int id) async {
    final resp =
    await ApiService.instance.dio.post('delivery/shipments/$id/advance/');
    return _asMap(resp.data);
  }

  // ---------------------------
  // PARSING active shipment
  // ---------------------------
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

    // на всякий: не вылетать по индексу
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

  // ---------------------------
  // FLOW: go online -> nearby
  // ---------------------------
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Рядом нет заказов')),
        );
        setState(() {
          _showWelcome = true;
          _nearby = const [];
          _nearbyIndex = 0;
        });
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

        _didFitOnce = false;
        _routeSignature = null;
        _routePoints = const [];
      });

      await _syncRouteAndCameraForNearby();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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

  // ---------------------------
  // FLOW: accept -> active + polling
  // ---------------------------
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

        _didFitOnce = false;
        _routeSignature = null;
        _routePoints = const [];
      });

      _startPolling(parsed.id);
      await _syncRouteAndCameraForActive();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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

      // если завершён/отменён — показываем финал (или возвращаемся на welcome)
      if (parsed.status == ShipmentStatus.canceled) {
        _stopActiveAndBackToWelcome(message: 'Заказ отменён');
        return;
      }

      await _syncRouteAndCameraForActive();
    } catch (_) {}
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // ---------------------------
  // advance (intermediate + finish)
  // ---------------------------
  Future<void> _advance() async {
    final id = _activeId;
    if (id == null) return;

    try {
      final raw = await _advanceRaw(id);
      final parsed =
      _parseActive(raw, fallbackIndex: _activeCurrentStopIndex + 1);

      if (!mounted) return;

      setState(() {
        _activeStatus = parsed.status;
        _activeCurrentStopIndex = parsed.currentStopIndex;
        _activeStops = parsed.stops;
        _activePublicCode = parsed.publicCode;
        _activeFare = parsed.fare;

        _didFitOnce = false; // после advance можно слегка обновить fit
        _routeSignature = null;
        _routePoints = const [];
      });

      await _syncRouteAndCameraForActive();

      if (parsed.status == ShipmentStatus.completed) {
        // показать "Заказ выполнен" как на скрине, а потом можно вернуться на welcome
        // (я оставляю на этом экране кнопку "Выполнено", ты можешь сделать авто-возврат)
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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

    // фильтр от NaN/Infinity и некорректных координат
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

    // если 1 точка — нельзя fit bounds (часто дает Infinity zoom)
    if (clean.length == 1) {
      _mapController.move(clean.first, 15);
      return;
    }

    final bounds = LatLngBounds.fromPoints(clean);

    // если bounds выродились (все точки одинаковые/слишком близко)
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
        CameraFit.bounds(
          bounds: bounds,
          padding: padding,
          maxZoom: 17,
        ),
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

  // ---------------------------
  // UI helpers
  // ---------------------------
  int _distanceToCurrentStopMeters() {
    if (!_hasActive || _activeStops.isEmpty) return 0;
    final i = _activeCurrentStopIndex.clamp(0, _activeStops.length - 1);
    final s = _activeStops[i];
    if (s.lat == null || s.lon == null) return 0;

    final d = Geolocator.distanceBetween(
      _myLat,
      _myLon,
      s.lat!,
      s.lon!,
    );
    return d.round();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final padding = MediaQuery.viewPaddingOf(context);
    final bottomSafe = padding.bottom;

    final myPoint = LatLng(_myLat, _myLon);

    // markers
    final markers = <Marker>[
      Marker(
        point: myPoint,
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: const _MeDot(),
      ),
    ];

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
                final c = pos.center;
                if (c == null) return;
                _centerLat = c.latitude;
                _centerLon = c.longitude;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'kg.genesis.dogo',
              ),

              if (_routePoints.isNotEmpty) ...[
                // чёрный "контур"
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5,
                      color: Colors.black.withOpacity(0.75),
                    ),
                  ],
                ),
                // белая линия сверху
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

              MarkerLayer(markers: markers),
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
                      Colors.black.withOpacity(0.08),
                      Colors.black.withOpacity(0.16),
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

// ---------------------------
// UI widgets
// ---------------------------

class _MeDot extends StatelessWidget {
  const _MeDot();

  static const _accent = Color(0xFFFF8A00);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: _accent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// маркер как на скрине: светло-персиковый кружок + белая обводка
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
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
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
              const Text(
                'Нажмите “На линию”, чтобы увидеть ближайшие заказы',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF9FA4AD),
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
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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

/// 1 экран: nearby (как слева снизу на скрине)
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
    final nearestHint = shipment.stops.isNotEmpty ? shipment.stops.first.shortHint : '';

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
            nearestHint.isNotEmpty ? 'Ближайшая подача: $nearestHint' : 'Ближайшая подача',
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
              _Chip(icon: Icons.inventory_2_outlined, label: 'Большие мешки'),
              const SizedBox(width: 8),
              _Chip(icon: Icons.map_outlined, label: '$stopsCount точки'),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${shipment.estimatedFare} сом',
            style: const TextStyle(
              fontSize: 22,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              Icon(Icons.add, size: 16, color: Color(0xFF22C55E)),
              SizedBox(width: 2),
              Text(
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('Забрать заказ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('Отказать', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2/3 экран: assigned / in_transit / кнопка advance
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

    final buttonText = (status == ShipmentStatus.assigned)
        ? 'На месте'
        : (isLast ? 'Выполнено' : 'Следующая точка');

    // показываем “предыдущая + текущая” как на скрине
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
          if (status == ShipmentStatus.assigned) ...[
            Text(
              '$distanceText от вас',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (stops.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.place_outlined, size: 18, color: accent),
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
            const SizedBox(height: 14),
          ] else ...[
            // in_transit: карточка точек как на скрине
            if (items.isNotEmpty) _TwoStopsCard(items: items, currentIndex: currentIndex),
            const SizedBox(height: 14),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: Text(buttonText, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TwoStopsCard extends StatelessWidget {
  const _TwoStopsCard({
    required this.items,
    required this.currentIndex,
  });

  final List<_StopUi> items;
  final int currentIndex;

  static const _green = Color(0xFF41C44B);
  static const _grey = Color(0xFFB7BCC5);

  @override
  Widget build(BuildContext context) {
    // item[0] = previous (если есть), item[1] = current
    final prev = items.length >= 2 ? items[0] : null;
    final cur = items.isNotEmpty ? items.last : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prev != null)
            _StopRow(
              title: prev.headerLine,
              subtitle: prev.subLine,
              trailing: const _TrailingStatus(text: 'Забрали груз', color: _grey),
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
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9AA0A6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        trailing,
      ],
    );
  }
}

class _TrailingStatus extends StatelessWidget {
  const _TrailingStatus({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 2,
          height: 44,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _ArrowDown extends StatelessWidget {
  const _ArrowDown();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 6),
        child: Icon(Icons.arrow_downward_rounded, size: 28, color: Colors.black),
      ),
    );
  }
}

/// экран "Заказ выполнен" (упрощённо, но в стиле скрина)
class _CompletedSheet extends StatelessWidget {
  const _CompletedSheet({
    required this.publicCode,
    required this.fare,
    required this.accent,
    required this.onDone,
  });

  final String publicCode;
  final int fare;
  final Color accent;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: Color(0x26000000), blurRadius: 18, offset: Offset(0, -4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF9AA0A6)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  big: '+$fare',
                  small: 'Сомов заработано',
                  icon: Icons.credit_card,
                  iconColor: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: _StatCard(
                  big: '+1',
                  small: 'К рейтингу',
                  icon: Icons.emoji_events_outlined,
                  iconColor: Color(0xFF22C55E),
                ),
              ),
            ],
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('Выполнено', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.big,
    required this.small,
    required this.icon,
    required this.iconColor,
  });

  final String big;
  final String small;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(big, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  small,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
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

  final IconData icon;
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_shipping_outlined, size: 18, color: Color(0xFFFF8A00)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
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
