import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dogo/features/main_module/map/provider/delivery_address_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../core/design/app_design.dart';
import '../../../../core/map/safa_yandex_map.dart';
import '../../../../core/utils/friendly_error.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../data/network/api_service.dart';
import '../../../../data/notifications/service/push_service.dart';
import '../../../../data/realtime/shipment_realtime_service.dart';
import '../../payments/data/repo/shipments_repository.dart';
import '../../services/service_config.dart';
import '../data/model/delivery_point_model.dart';
import '../data/model/delivery_refs_models.dart';
import '../data/model/market_map_feature.dart';
import '../data/model/shipment_status.dart';
import '../data/repo/delivery_refs_repository.dart';
import '../data/repo/market_map_repository.dart';
import '../provider/active_shipment_provider.dart';
import 'components/container_details_sheet.dart';
import 'components/order_completed_sheet.dart';
import 'components/order_fulfillment_sheet.dart';
import 'components/order_summary_sheet.dart';
import 'components/point_picker_sheet.dart';
import 'components/search_sheet.dart';
import 'components/service_order_panel.dart';
import 'components/shipment_payment_sheet.dart';
import 'widgets/container_map_marker.dart';
import 'widgets/here_bubble.dart';
import 'widgets/market_map_layers.dart';
import 'widgets/me_dot.dart';
import 'widgets/parsed_adress.dart';

class OrderMapScreen extends StatefulWidget {
  const OrderMapScreen({super.key, this.serviceType = 'delivery'});

  final String serviceType;

  @override
  State<OrderMapScreen> createState() => _OrderMapScreenState();
}

enum _LocationGate { checking, ready, denied, serviceOff }

class _OrderMapScreenState extends State<OrderMapScreen>
    with WidgetsBindingObserver {
  /// Ниже этого масштаба подписи контейнеров скрываются, чтобы карта
  /// не превращалась в визуальный хаос.
  static const double _containerLabelMinZoom = 17;
  static const double _containerShapeMinZoom = 15;
  static const int _maxRenderedLooseContainers = 180;
  static const int _maxRenderedContainerMarkers = 96;
  static const int _maxRenderedContainerLabels = 120;
  static const int _maxRenderedPublishedContainers = 260;

  ServiceConfig get _config => ServiceConfig.fromType(widget.serviceType);

  double _myLat = 42.8746;
  double _myLon = 74.6122;

  double _centerLat = 42.8746;
  double _centerLon = 74.6122;
  double _zoom = 15;

  final SafaMapController _mapController = SafaMapController();
  final DeliveryRefsRepository _refsRepository = DeliveryRefsRepository();
  final MarketMapRepository _marketMapRepository = MarketMapRepository();
  final TextEditingController _descriptionController = TextEditingController();

  DeliveryPoint? _deliveryPoint;
  DeliveryPoint? _fromPoint;
  final List<DeliveryPoint> _intermediatePoints = [];

  int? _activeShipmentId;
  bool _creatingShipment = false;
  bool _cancellingShipment = false;
  String? _panelError;

  bool get _searchMode => _activeShipmentId != null;
  bool _showFulfillmentSheet = false;
  bool _bootstrappedActive = false;
  List<DeliveryPoint> _activeStops = const [];
  bool _didInitialMove = false;
  _LocationGate _gate = _LocationGate.checking;
  bool _didFitOnFulfillment = false;

  Timer? _shipmentPollTimer;
  StreamSubscription<Map<String, dynamic>>? _pushSub;
  late final ShipmentRealtimeService _shipmentRealtime;
  bool _shipmentPollInFlight = false;
  ShipmentStatus _currentStatus = ShipmentStatus.unknown;
  String _currentStatusCode = 'pending';
  bool _isPaid = true;
  int _fare = 0;
  String? _carrierFirstName;
  String? _carrierPhone;
  String? _carrierAvatarUrl;
  String? _carrierSpecialistType;
  String? _shipmentUiSignature;
  bool _orderPanelCollapsed = false;
  LatLng? _courierPosition;
  DateTime? _courierPositionUpdatedAt;
  bool _didFitCourierOnce = false;

  List<LatLng> _routePoints = const [];
  String? _routeSignature;
  bool _routing = false;
  Timer? _routeRetryTimer;

  StreamSubscription<ServiceStatus>? _serviceStatusStream;
  Timer? _containersDebounce;
  Timer? _marketMapDebounce;
  Timer? _mapIdleDebounce;
  List<ContainerRef> _visibleContainers = const [];
  ContainerRef? _selectedContainer;
  bool _mapMoving = false;
  bool _containersLoading = false;
  bool _containersRefreshPending = false;
  int _containersRequestSerial = 0;
  LatLngBounds? _lastContainersBounds;
  int? _lastContainersZoomBucket;

  List<MarketMapFeature> _marketMapFeatures = const [];
  MarketMapRenderData? _marketMapRenderCache;
  int? _marketMapRenderZoomBucket;
  int? _marketMapRenderFeatureCount;
  int? _marketMapRenderFeatureHash;
  int? _marketMapRenderCenterLatBucket;
  int? _marketMapRenderCenterLonBucket;
  bool? _marketMapRenderMoving;
  Set<int> _publishedContainerIdsCache = const {};
  int? _publishedContainerHash;
  bool _marketMapLoading = false;
  bool _marketMapRefreshPending = false;
  int _marketMapRequestSerial = 0;
  LatLngBounds? _lastMarketMapBounds;
  int? _lastMarketMapZoomBucket;

  // --- Маршрут OSRM -----------------------------------------------------

  List<LatLng> _extractStopPoints(List<DeliveryPoint> stops) {
    final pts = <LatLng>[];
    for (final s in stops) {
      final lat = s.lat;
      final lon = s.lon;
      if (lat == null || lon == null) continue;
      pts.add(LatLng(lat, lon));
    }
    return pts;
  }

  String _makeSignature(List<LatLng> pts) {
    String f(double v) => v.toStringAsFixed(6);
    return pts.map((p) => '${f(p.latitude)},${f(p.longitude)}').join('|');
  }

  Future<List<LatLng>> _buildOsrmRoute(List<LatLng> stops) async {
    if (stops.length < 2) return const [];
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    // Один запрос сохраняет порядок всех остановок A → B → C. Отдельные
    // запросы для каждого плеча чаще попадали под rate limit и оставляли на
    // карте прямые сегменты вместо дороги.
    final coords = stops.map((p) => '${p.longitude},${p.latitude}').join(';');

    try {
      final resp = await dio.get(
        'https://router.project-osrm.org/route/v1/driving/$coords',
        queryParameters: {
          'overview': 'full',
          'geometries': 'geojson',
          'steps': 'false',
          'alternatives': 'false',
          'continue_straight': 'false',
          'radiuses': List.filled(stops.length, 'unlimited').join(';'),
        },
      );

      final data = resp.data;
      final routes = (data is Map) ? data['routes'] : null;
      if (routes is! List || routes.isEmpty) return const [];

      final geom = routes.first['geometry'];
      final coordsList = (geom is Map) ? geom['coordinates'] : null;
      if (coordsList is! List) return const [];

      final out = <LatLng>[];
      for (final c in coordsList) {
        if (c is! List || c.length < 2) continue;
        final lon = (c[0] as num).toDouble();
        final lat = (c[1] as num).toDouble();
        out.add(LatLng(lat, lon));
      }

      if (out.length >= 2) return _dedupeRoutePoints(out);
    } catch (_) {
      // При временной ошибке не показываем вводящую в заблуждение прямую.
    }

    return const [];
  }

  double _distanceMeters(LatLng a, LatLng b) {
    return const Distance().as(LengthUnit.Meter, a, b);
  }

  List<LatLng> _dedupeRoutePoints(List<LatLng> points) {
    final out = <LatLng>[];
    for (final point in points) {
      if (out.isEmpty || _distanceMeters(out.last, point) > 0.5) {
        out.add(point);
      }
    }
    return out;
  }

  Future<List<LatLng>> _buildRouteMultiLeg(List<LatLng> pts) async {
    if (pts.length < 2) return const [];
    return _buildOsrmRoute(pts);
  }

  // --- Контейнеры -------------------------------------------------------

  void _scheduleContainersRefresh({bool immediate = false}) {
    if (!SafaMobileMapFeatures.backendDrawingLayersEnabled) return;
    _containersDebounce?.cancel();
    _containersDebounce = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 450),
      _refreshVisibleContainers,
    );
  }

  Future<void> _refreshVisibleContainers() async {
    if (!SafaMobileMapFeatures.backendDrawingLayersEnabled) return;
    if (!mounted) return;
    if (_containersLoading) {
      _containersRefreshPending = true;
      return;
    }

    late final LatLngBounds bounds;
    try {
      bounds = _mapController.visibleBounds!;
    } catch (_) {
      return;
    }

    final zoomBucket = _zoom.floor();
    final previousBounds = _lastContainersBounds;
    if (previousBounds != null &&
        _lastContainersZoomBucket == zoomBucket &&
        !_shouldReloadContainers(previousBounds, bounds)) {
      return;
    }

    final serial = ++_containersRequestSerial;
    final latPadding =
        (bounds.north - bounds.south).abs().clamp(0.002, 0.03) * 0.25;
    final lonPadding =
        (bounds.east - bounds.west).abs().clamp(0.002, 0.03) * 0.25;

    if (_visibleContainers.isEmpty) {
      setState(() => _containersLoading = true);
    } else {
      _containersLoading = true;
    }

    try {
      final containers = await _refsRepository.loadContainersInBounds(
        minLat: bounds.south - latPadding,
        maxLat: bounds.north + latPadding,
        minLon: bounds.west - lonPadding,
        maxLon: bounds.east + lonPadding,
      );

      if (!mounted || serial != _containersRequestSerial) return;

      // Выбранный контейнер остаётся на карте, даже если вышел за границы
      // текущего запроса.
      final selected = _selectedContainer;
      final merged = List<ContainerRef>.from(containers);
      if (selected != null && !merged.any((item) => item.id == selected.id)) {
        merged.add(selected);
      }

      // Один setState на успешный ответ вместо трёх.
      setState(() {
        _visibleContainers = merged;
        _containersLoading = false;
        _lastContainersBounds = bounds;
        _lastContainersZoomBucket = zoomBucket;
      });
      _runPendingContainersRefresh();
    } catch (_) {
      // При кратковременной сетевой ошибке сохраняем последние успешно
      // загруженные маркеры — раньше они пропадали с карты.
      if (!mounted || serial != _containersRequestSerial) return;
      if (_visibleContainers.isEmpty) {
        setState(() => _containersLoading = false);
      } else {
        _containersLoading = false;
      }
      _runPendingContainersRefresh();
    }
  }

  void _runPendingContainersRefresh() {
    if (!_containersRefreshPending || !mounted) return;
    _containersRefreshPending = false;
    _scheduleContainersRefresh(immediate: true);
  }

  Future<void> _focusContainers() async {
    if (!SafaMobileMapFeatures.backendDrawingLayersEnabled) return;
    if (_containersLoading) return;

    setState(() => _containersLoading = true);
    try {
      final containers = await _refsRepository.searchContainers(pageSize: 200);
      final points = containers
          .where((c) => c.latValue != null && c.lonValue != null)
          .map((c) => LatLng(c.latValue!, c.lonValue!))
          .toList();

      if (!mounted) return;
      setState(() {
        _visibleContainers = containers;
        _containersLoading = false;
        _lastContainersBounds = null;
        _lastContainersZoomBucket = null;
      });

      if (points.isNotEmpty) {
        _fitToPoints(points);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _containersLoading = false);
      AppSnackBar.showError(
        context,
        error: e,
        message: friendlyErrorMessage(
          e,
          fallback: 'Не удалось загрузить контейнеры',
        ),
      );
    }
  }

  void _scheduleMarketMapRefresh({bool immediate = false}) {
    if (!SafaMobileMapFeatures.backendDrawingLayersEnabled) return;
    _marketMapDebounce?.cancel();
    _marketMapDebounce = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 450),
      _loadMarketMap,
    );
  }

  void _setMapMoving(bool moving) {
    if (_mapMoving == moving) return;
    _mapMoving = moving;
    _marketMapRenderCache = null;
    if (mounted) setState(() {});
  }

  void _scheduleMapIdle() {
    _mapIdleDebounce?.cancel();
    _mapIdleDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _setMapMoving(false);
      _scheduleContainersRefresh(immediate: true);
      _scheduleMarketMapRefresh(immediate: true);
    });
  }

  Future<void> _loadMarketMap() async {
    if (!SafaMobileMapFeatures.backendDrawingLayersEnabled) return;
    if (_marketMapLoading) {
      _marketMapRefreshPending = true;
      return;
    }

    late final LatLngBounds bounds;
    try {
      bounds = _mapController.visibleBounds!;
    } catch (_) {
      return;
    }

    final zoomBucket = _zoom.floor();
    final previousBounds = _lastMarketMapBounds;
    if (previousBounds != null &&
        _lastMarketMapZoomBucket == zoomBucket &&
        !_shouldReloadContainers(previousBounds, bounds)) {
      return;
    }

    final serial = ++_marketMapRequestSerial;
    _marketMapLoading = true;
    final latPadding =
        (bounds.north - bounds.south).abs().clamp(0.002, 0.03) * 0.2;
    final lonPadding =
        (bounds.east - bounds.west).abs().clamp(0.002, 0.03) * 0.2;

    try {
      final collection = await _marketMapRepository.loadPublished(
        zoom: zoomBucket,
        minLat: bounds.south - latPadding,
        maxLat: bounds.north + latPadding,
        minLon: bounds.west - lonPadding,
        maxLon: bounds.east + lonPadding,
        centerLat: _centerLat,
        centerLon: _centerLon,
        maxContainers: _maxRenderedPublishedContainers * 2,
      );
      if (!mounted || serial != _marketMapRequestSerial) return;
      setState(() {
        _marketMapFeatures = collection.features;
        _marketMapRenderCache = null;
        _publishedContainerHash = null;
        _routeSignature = null;
        _marketMapLoading = false;
        _lastMarketMapBounds = bounds;
        _lastMarketMapZoomBucket = zoomBucket;
      });
      _runPendingMarketMapRefresh();
      unawaited(_syncRouteAndCamera());
    } catch (_) {
      if (!mounted || serial != _marketMapRequestSerial) return;
      setState(() => _marketMapLoading = false);
      _runPendingMarketMapRefresh();
    }
  }

  void _runPendingMarketMapRefresh() {
    if (!_marketMapRefreshPending || !mounted) return;
    _marketMapRefreshPending = false;
    _scheduleMarketMapRefresh(immediate: true);
  }

  void _fitToPoints(List<LatLng> pts) {
    if (pts.isEmpty) return;

    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final padding = EdgeInsets.fromLTRB(36, 96, 36, 300 + bottomSafe);

    _mapController.fitBounds(LatLngBounds.fromPoints(pts), padding: padding);
  }

  Future<void> _syncRouteAndCamera() async {
    if (!mounted) return;

    final List<LatLng> pts;
    if (_activeShipmentId != null) {
      if (!_showFulfillmentSheet && !_searchMode) {
        _routeRetryTimer?.cancel();
        _routeRetryTimer = null;
        if (_routePoints.isNotEmpty || _routeSignature != null) {
          setState(() {
            _routePoints = const [];
            _routeSignature = null;
          });
        }
        _didFitOnFulfillment = false;
        return;
      }
      pts = _extractStopPoints(_activeStops);
      if (!_didFitOnFulfillment && pts.isNotEmpty) {
        _didFitOnFulfillment = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fitToPoints(pts);
        });
      }
    } else {
      // Предпросмотр маршрута при создании заказа сразу после выбора точек
      final creationPts = <LatLng>[];
      if (_fromPoint?.lat != null && _fromPoint?.lon != null) {
        creationPts.add(LatLng(_fromPoint!.lat!, _fromPoint!.lon!));
      } else if (_fromPoint == null && _myLat.isFinite && _myLon.isFinite) {
        creationPts.add(LatLng(_myLat, _myLon));
      }
      for (final p in _intermediatePoints) {
        if (p.lat != null && p.lon != null) {
          creationPts.add(LatLng(p.lat!, p.lon!));
        }
      }
      if (_deliveryPoint?.lat != null && _deliveryPoint?.lon != null) {
        creationPts.add(LatLng(_deliveryPoint!.lat!, _deliveryPoint!.lon!));
      }
      pts = creationPts;
    }

    if (pts.length < 2) {
      if (_routePoints.isNotEmpty || _routeSignature != null) {
        setState(() {
          _routePoints = const [];
          _routeSignature = null;
        });
      }
      return;
    }

    final sig = _makeSignature(pts);
    if (_routeSignature == sig) return;
    if (_routing) return;

    _routing = true;
    try {
      final route = await _buildRouteMultiLeg(pts);
      if (!mounted) return;

      setState(() {
        _routeSignature = route.isNotEmpty ? sig : null;
        _routePoints = route;
      });

      if (route.isNotEmpty && _activeShipmentId == null) {
        _fitToPoints(pts);
      }

      _routeRetryTimer?.cancel();
      _routeRetryTimer = null;
      if (route.isEmpty && mounted && _activeShipmentId != null) {
        _routeRetryTimer = Timer(const Duration(seconds: 5), () {
          _routeRetryTimer = null;
          if (mounted && _activeShipmentId != null) {
            unawaited(_syncRouteAndCamera());
          }
        });
      }
    } finally {
      _routing = false;
    }
  }

  // --- Жизненный цикл ---------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shipmentRealtime = ShipmentRealtimeService(
      onEvent: _handleShipmentRealtimeEvent,
    );
    _pushSub = PushService.instance.events.listen(_handlePushEvent);

    _serviceStatusStream = Geolocator.getServiceStatusStream().listen((status) {
      if (status == ServiceStatus.enabled) {
        _initLocation();
      } else {
        if (mounted) setState(() => _gate = _LocationGate.serviceOff);
        _promptGps();
      }
    });

    _initLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      _scheduleMarketMapRefresh(immediate: true);
      final p = context.read<ActiveShipmentProvider>();
      await p.load();
      if (!mounted) return;

      final active = p.active;
      if (active == null) return;
      if (_activeShipmentId != null) return;
      if (_bootstrappedActive) return;
      _bootstrappedActive = true;

      final status = parseShipmentStatus(active.status);

      setState(() {
        _activeShipmentId = active.id;
        _activeStops = active.stops;
        _currentStatus = status;
        _currentStatusCode = active.status;
        _isPaid = active.isPaid;
        _fare = active.fare;
        _carrierFirstName = active.carrierFirstName;
        _carrierPhone = active.carrierPhone;
        _carrierAvatarUrl = active.carrierAvatarUrl;
        _carrierSpecialistType = active.carrierSpecialistType;
        _showFulfillmentSheet =
            status == ShipmentStatus.assigned ||
            status == ShipmentStatus.inTransit;
      });

      _startShipmentPolling(active.id);
      _syncRouteAndCamera();
    });
  }

  @override
  void didUpdateWidget(covariant OrderMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serviceType == widget.serviceType ||
        _activeShipmentId != null) {
      return;
    }
    setState(() {
      _deliveryPoint = null;
      _fromPoint = null;
      _intermediatePoints.clear();
      _descriptionController.clear();
      _panelError = null;
      _selectedContainer = null;
      _routePoints = const [];
      _routeSignature = null;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initLocation();
      final id = _activeShipmentId;
      if (id != null) {
        _shipmentRealtime.reconnect();
        unawaited(_pollShipment(id));
      }
    }
  }

  void _handlePushEvent(Map<String, dynamic> data) {
    if (data['type']?.toString() != 'shipment_status') return;
    final id = int.tryParse(data['shipment_id']?.toString() ?? '');
    if (id != null && id == _activeShipmentId) {
      unawaited(_pollShipment(id));
    }
  }

  void _handleShipmentRealtimeEvent(Map<String, dynamic> event) {
    if (!mounted) return;
    final activeId = _activeShipmentId;
    if (activeId == null) return;
    final eventShipmentId = int.tryParse(
      event['shipment_id']?.toString() ?? '',
    );
    if (eventShipmentId != null && eventShipmentId != activeId) return;

    final telemetry = ShipmentCourierTelemetry.tryParse(event);
    if (telemetry != null) {
      if (telemetry.shipmentId != activeId) return;
      final firstPosition = _courierPosition == null;
      setState(() {
        _courierPosition = LatLng(telemetry.lat, telemetry.lon);
        _courierPositionUpdatedAt = telemetry.updatedAt;
      });

      if (firstPosition && !_didFitCourierOnce) {
        _didFitCourierOnce = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _courierPosition == null) return;
          _fitToPoints([
            _courierPosition!,
            ..._extractStopPoints(_activeStops),
          ]);
        });
      }
      return;
    }

    unawaited(_pollShipment(activeId));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serviceStatusStream?.cancel();
    _pushSub?.cancel();
    _shipmentRealtime.dispose();
    _containersDebounce?.cancel();
    _marketMapDebounce?.cancel();
    _mapIdleDebounce?.cancel();
    _routeRetryTimer?.cancel();
    _descriptionController.dispose();
    _stopShipmentPolling();
    super.dispose();
  }

  // --- Геолокация -------------------------------------------------------

  Future<void> _initLocation() async {
    final addressProvider = context.read<DeliveryAddressProvider>();

    try {
      if (mounted) setState(() => _gate = _LocationGate.checking);

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _gate = _LocationGate.serviceOff);
        _promptGps();
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _gate = _LocationGate.denied);
        if (!mounted) return;
        AppSnackBar.showError(
          context,
          message:
              'Доступ к местоположению запрещён. '
              'Разрешите его, чтобы карта работала корректно.',
          actionLabel: 'Настройки',
          onAction: () async {
            await Geolocator.openAppSettings();
          },
        );
        return;
      }

      if (perm == LocationPermission.denied) {
        if (mounted) setState(() => _gate = _LocationGate.denied);
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
        _gate = _LocationGate.ready;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_gate != _LocationGate.ready) return;
        if (_didInitialMove) return;
        _didInitialMove = true;

        _mapController.move(LatLng(_myLat, _myLon), 15);
      });

      await addressProvider.fetchGpsHereAddress(
        lat: _myLat,
        lon: _myLon,
        preferPublicAddress:
            _config.type == 'delivery' || _config.type == 'cars',
      );
    } catch (e, st) {
      debugPrint('initLocation error: $e\n$st');
      if (mounted) setState(() => _gate = _LocationGate.denied);
    }
  }

  void _promptGps() {
    if (!mounted) return;
    AppSnackBar.showError(
      context,
      message:
          'Геолокация отключена. Включите GPS, чтобы видеть себя на карте.',
      actionLabel: 'Включить',
      onAction: () async {
        await Geolocator.openLocationSettings();
      },
    );
  }

  void _goToMyLocation() {
    if (_gate != _LocationGate.ready) {
      _initLocation();
      return;
    }
    _mapController.move(LatLng(_myLat, _myLon), 16);
  }

  List<LatLng> _spreadSamePoints(List<LatLng> pts) {
    final used = <String, int>{};

    String key(LatLng p) =>
        '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}';

    final out = <LatLng>[];
    for (final p in pts) {
      final k = key(p);
      final n = used[k] ?? 0;
      used[k] = n + 1;

      if (n == 0) {
        out.add(p);
      } else {
        final delta = 0.00002 * n;
        out.add(LatLng(p.latitude + delta, p.longitude + delta));
      }
    }
    return out;
  }

  int _marketFeatureHash() {
    var hash = 17;
    for (final feature in _marketMapFeatures) {
      hash = 37 * hash + feature.id.hashCode;
      hash = 37 * hash + feature.kind.hashCode;
      hash = 37 * hash + feature.minZoom;
    }
    return hash;
  }

  MarketMapRenderData _marketMapRenderData() {
    if (_mapMoving) return MarketMapRenderData.empty;
    final zoomBucket = _zoom.floor();
    final centerLatBucket = (_centerLat * 10000).round();
    final centerLonBucket = (_centerLon * 10000).round();
    final hash = _marketFeatureHash();
    final cached = _marketMapRenderCache;
    if (cached != null &&
        _marketMapRenderZoomBucket == zoomBucket &&
        _marketMapRenderFeatureCount == _marketMapFeatures.length &&
        _marketMapRenderFeatureHash == hash &&
        _marketMapRenderCenterLatBucket == centerLatBucket &&
        _marketMapRenderCenterLonBucket == centerLonBucket &&
        _marketMapRenderMoving == _mapMoving) {
      return cached;
    }

    final next = MarketMapRenderData.fromFeatures(
      _marketMapFeatures,
      zoom: _zoom,
      center: LatLng(_centerLat, _centerLon),
      maxContainerFeatures: _maxRenderedPublishedContainers,
      showLabels: true,
    );
    _marketMapRenderCache = next;
    _marketMapRenderZoomBucket = zoomBucket;
    _marketMapRenderFeatureCount = _marketMapFeatures.length;
    _marketMapRenderFeatureHash = hash;
    _marketMapRenderCenterLatBucket = centerLatBucket;
    _marketMapRenderCenterLonBucket = centerLonBucket;
    _marketMapRenderMoving = _mapMoving;
    return next;
  }

  Set<int> _publishedContainerIds() {
    final hash = _marketFeatureHash();
    if (_publishedContainerHash == hash) return _publishedContainerIdsCache;
    final ids = _marketMapFeatures
        .where((feature) => feature.isContainer)
        .map(_marketMapContainerId)
        .whereType<int>()
        .toSet();
    _publishedContainerHash = hash;
    _publishedContainerIdsCache = ids;
    return ids;
  }

  List<MarketMapFeature> _renderedMarketMapContainerFeatures() {
    if (_mapMoving) return const [];
    if (_zoom < _containerShapeMinZoom) return const [];
    final center = LatLng(_centerLat, _centerLon);
    final features =
        _marketMapFeatures
            .where((feature) => feature.isContainer && feature.minZoom <= _zoom)
            .map((feature) {
              final lat = feature.centerLat;
              final lon = feature.centerLon;
              final point = lat != null && lon != null
                  ? LatLng(lat, lon)
                  : _featureCenter(feature.coordinates);
              if (point == null) return null;
              final dLat = point.latitude - center.latitude;
              final dLon = point.longitude - center.longitude;
              return MapEntry(feature, dLat * dLat + dLon * dLon);
            })
            .whereType<MapEntry<MarketMapFeature, double>>()
            .toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    final renderLimit = MarketMapRenderData.containerRenderLimitForZoom(_zoom);
    if (features.length <= renderLimit) {
      return features.map((entry) => entry.key).toList();
    }
    return features.take(renderLimit).map((entry) => entry.key).toList();
  }

  bool _shouldReloadContainers(LatLngBounds previous, LatLngBounds next) {
    final previousLatSpan = (previous.north - previous.south).abs();
    final previousLonSpan = (previous.east - previous.west).abs();
    final previousCenter = previous.center;
    final nextCenter = next.center;
    final latShift = (previousCenter.latitude - nextCenter.latitude).abs();
    final lonShift = (previousCenter.longitude - nextCenter.longitude).abs();
    return latShift > previousLatSpan * 0.25 ||
        lonShift > previousLonSpan * 0.25;
  }

  // --- Состояние заказа -------------------------------------------------

  void _stopShipmentPolling() {
    _shipmentRealtime.disconnect();
    _shipmentPollTimer?.cancel();
    _shipmentPollTimer = null;
  }

  void _resetShipmentState() {
    setState(() {
      _activeShipmentId = null;
      _showFulfillmentSheet = false;
      _activeStops = const [];
      _currentStatus = ShipmentStatus.unknown;
      _currentStatusCode = 'pending';
      _shipmentUiSignature = null;
      _bootstrappedActive = false;
      _didFitOnFulfillment = false;
      _routePoints = const [];
      _routeSignature = null;
      _isPaid = true;
      _fare = 0;
      _carrierFirstName = null;
      _carrierPhone = null;
      _carrierAvatarUrl = null;
      _carrierSpecialistType = null;
      _courierPosition = null;
      _courierPositionUpdatedAt = null;
      _didFitCourierOnce = false;
    });

    context.read<ActiveShipmentProvider>().clear();
  }

  Future<void> _pollShipment(int shipmentId) async {
    if (_shipmentPollInFlight) return;
    _shipmentPollInFlight = true;
    try {
      final dto = await context.read<ActiveShipmentProvider>().getById(
        shipmentId,
      );
      if (!mounted) return;

      final status = parseShipmentStatus(dto.status);
      if (status == ShipmentStatus.completed ||
          status == ShipmentStatus.canceled) {
        _stopShipmentPolling();
        _resetShipmentState();
        if (status == ShipmentStatus.completed) {
          _deliveryPoint = null;
          _fromPoint = null;
          _intermediatePoints.clear();
          _descriptionController.clear();
          _showOrderCompletedSheet();
        }
        return;
      }

      final shouldShowFulfillment =
          status == ShipmentStatus.assigned ||
          status == ShipmentStatus.inTransit;

      final nextSignature = Object.hash(
        dto.status,
        dto.isPaid,
        dto.fare,
        dto.carrierFirstName,
        dto.carrierPhone,
        dto.carrierAvatarUrl,
        dto.carrierSpecialistType,
        shouldShowFulfillment,
        Object.hashAll(
          dto.stops.map(
            (stop) =>
                Object.hash(stop.title, stop.lat, stop.lon, stop.container),
          ),
        ),
      ).toString();
      if (_shipmentUiSignature == nextSignature) return;

      setState(() {
        _currentStatus = status;
        _currentStatusCode = dto.status;
        _activeStops = dto.stops;
        _showFulfillmentSheet = shouldShowFulfillment;
        _isPaid = dto.isPaid;
        _fare = dto.fare;
        _carrierFirstName = dto.carrierFirstName;
        _carrierPhone = dto.carrierPhone;
        _carrierAvatarUrl = dto.carrierAvatarUrl;
        _carrierSpecialistType = dto.carrierSpecialistType;
        _shipmentUiSignature = nextSignature;
      });

      _syncRouteAndCamera();
    } catch (_) {
      // Поллинг переживает единичные сетевые ошибки без вмешательства в UI.
    } finally {
      _shipmentPollInFlight = false;
    }
  }

  Future<void> _refreshShipmentAfterPayment(int shipmentId) async {
    // A periodic request may be finishing with the pre-payment snapshot.
    // Wait briefly for it and then make one guaranteed fresh request.
    for (var attempt = 0; attempt < 20 && _shipmentPollInFlight; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    await _pollShipment(shipmentId);
  }

  void _showOrderCompletedSheet() {
    if (!mounted) return;
    showAppBottomSheet<void>(
      context: context,
      builder: (_) => const OrderCompletedSheet(),
    );
  }

  void _startShipmentPolling(int shipmentId) {
    _shipmentRealtime.connect(shipmentId);
    _shipmentPollTimer?.cancel();
    _shipmentPollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _pollShipment(shipmentId),
    );
    _pollShipment(shipmentId);
  }

  // --- Выбор точек ------------------------------------------------------

  Future<DeliveryPoint?> _openPointPicker({
    required PointPickerMode mode,
    double? lat,
    double? lon,
    int? stopNumber,
    String? headline,
    String? headlineSubtitle,
  }) {
    return showAppBottomSheet<DeliveryPoint>(
      context: context,
      builder: (_) => PointPickerSheet(
        mode: mode,
        lat: lat ?? _centerLat,
        lon: lon ?? _centerLon,
        stopNumber: stopNumber,
        headline: headline,
        headlineSubtitle: headlineSubtitle,
        addressOnly: _config.type == 'delivery' || _config.type == 'cars',
      ),
    );
  }

  Future<void> _editFromPoint({
    required String fromTitle,
    String? bazarTitle,
  }) async {
    final result = await _openPointPicker(
      mode: PointPickerMode.from,
      lat: _myLat,
      lon: _myLon,
      headline: _fromPoint?.title ?? fromTitle,
      headlineSubtitle: bazarTitle,
    );

    if (result != null && mounted) {
      setState(() {
        _fromPoint = result;
        _panelError = null;
      });
      unawaited(_syncRouteAndCamera());
    }
  }

  Future<void> _editDestination() async {
    final result = await _openPointPicker(
      mode: PointPickerMode.destination,
      headline: _deliveryPoint?.title,
    );

    if (result != null && mounted) {
      setState(() {
        _deliveryPoint = result;
        _panelError = null;
      });
      unawaited(_syncRouteAndCamera());
    }
  }

  Future<void> _addIntermediatePoint() async {
    final result = await _openPointPicker(
      mode: PointPickerMode.intermediate,
      stopNumber: _intermediatePoints.length + 1,
    );

    if (result != null && mounted) {
      setState(() {
        _intermediatePoints.add(result);
        _panelError = null;
      });
      unawaited(_syncRouteAndCamera());
    }
  }

  Future<void> _editIntermediatePoint(int index) async {
    if (index < 0 || index >= _intermediatePoints.length) return;

    final result = await _openPointPicker(
      mode: PointPickerMode.intermediate,
      stopNumber: index + 1,
      headline: _intermediatePoints[index].title,
    );

    if (result != null && mounted) {
      setState(() => _intermediatePoints[index] = result);
      unawaited(_syncRouteAndCamera());
    }
  }

  Future<void> _removeIntermediatePoint(int index) async {
    if (index < 0 || index >= _intermediatePoints.length) return;

    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Удалить остановку ${index + 1}?',
      message: _intermediatePoints[index].title,
      confirmLabel: 'Удалить',
      danger: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _intermediatePoints.removeAt(index));
    unawaited(_syncRouteAndCamera());
  }

  void _reorderIntermediatePoints(int oldIndex, int newIndex) {
    setState(() {
      final point = _intermediatePoints.removeAt(oldIndex);
      _intermediatePoints.insert(newIndex, point);
    });
    unawaited(_syncRouteAndCamera());
  }

  Future<void> _onContainerTapped(ContainerRef container) async {
    if (container.latValue == null || container.lonValue == null) return;

    setState(() => _selectedContainer = container);
    _mapController.move(
      LatLng(container.latValue!, container.lonValue!),
      _zoom < 17 ? 17 : _zoom,
    );

    final assignment = await showAppBottomSheet<ContainerAssignment>(
      context: context,
      builder: (_) =>
          ContainerDetailsSheet(container: container, config: _config),
    );

    if (!mounted || assignment == null) return;

    final point = _pointFromContainer(container);

    setState(() {
      _panelError = null;
      switch (assignment) {
        case ContainerAssignment.from:
          _fromPoint = point;
        case ContainerAssignment.destination:
          _deliveryPoint = point;
        case ContainerAssignment.intermediate:
          _intermediatePoints.add(point);
      }
    });
    unawaited(_syncRouteAndCamera());
  }

  Future<void> _onMarketMapContainerTapped(MarketMapFeature feature) async {
    final containerId = _marketMapContainerId(feature);
    final center = _featureCenter(feature.coordinates);
    if (center == null) return;

    ContainerRef container;
    if (containerId != null) {
      try {
        container = await _refsRepository.getContainer(containerId);
      } catch (_) {
        container = _containerRefFromFeature(feature, center);
      }
    } else {
      container = _containerRefFromFeature(feature, center);
    }

    if (!mounted) return;
    await _onContainerTapped(container);
  }

  int? _marketMapContainerId(MarketMapFeature feature) {
    final raw = feature.properties['container_id'];
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  ContainerRef _containerRefFromFeature(
    MarketMapFeature feature,
    LatLng center,
  ) {
    final props = feature.properties;
    String stringProp(String key) => (props[key] ?? '').toString();
    int intProp(String key) {
      final raw = props[key];
      if (raw is num) return raw.toInt();
      return int.tryParse(raw?.toString() ?? '') ?? 0;
    }

    final number = stringProp('number').trim().isNotEmpty
        ? stringProp('number').trim()
        : feature.name;

    return ContainerRef(
      id: _marketMapContainerId(feature) ?? -feature.id.hashCode.abs(),
      bazarId: intProp('bazar_id'),
      bazarName: stringProp('bazar_name'),
      passageId: intProp('passage_id'),
      passageNumber: stringProp('passage_number'),
      number: number,
      title: stringProp('title'),
      isActive: true,
      lat: center.latitude.toString(),
      lon: center.longitude.toString(),
      uiLabel: number,
      displayTitle: number,
    );
  }

  LatLng? _featureCenter(dynamic coordinates) {
    final points = <LatLng>[];
    void visit(dynamic raw) {
      if (raw is List && raw.length >= 2 && raw[0] is num && raw[1] is num) {
        points.add(
          LatLng((raw[1] as num).toDouble(), (raw[0] as num).toDouble()),
        );
        return;
      }
      if (raw is List) {
        for (final item in raw) {
          visit(item);
        }
      }
    }

    visit(coordinates);
    if (points.isEmpty) return null;
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

  DeliveryPoint _pointFromContainer(ContainerRef container) {
    final bazar = container.bazarName.trim();
    final number = container.number.trim();
    final passage = container.passageNumber.trim();

    final subtitleParts = <String>[
      if (number.isNotEmpty) 'Контейнер: $number',
      if (passage.isNotEmpty) 'Проход: $passage',
    ];

    return DeliveryPoint(
      title: bazar.isNotEmpty ? bazar : 'Контейнер $number',
      subtitle: subtitleParts.join(' • '),
      lat: container.latValue,
      lon: container.lonValue,
      bazar: bazar,
      container: number,
      passage: passage,
      q: '',
    );
  }

  // --- Создание и отмена заказа ----------------------------------------

  Future<void> _cancelShipment({String targetStatus = 'canceled'}) async {
    final id = _activeShipmentId;
    if (id == null || _cancellingShipment) return;

    if (targetStatus == 'canceled') {
      final confirmed = await AppConfirmDialog.show(
        context,
        title: 'Отменить заказ?',
        message: 'Поиск исполнителя будет остановлен.',
        confirmLabel: 'Отменить заказ',
        cancelLabel: 'Оставить',
        danger: true,
      );
      if (!confirmed || !mounted) return;
    }

    setState(() => _cancellingShipment = true);

    try {
      if (targetStatus == 'canceled') _stopShipmentPolling();

      await ApiService.instance.patchShipmentStatus(id, status: targetStatus);

      if (!mounted) return;

      if (targetStatus == 'canceled') {
        _resetShipmentState();
        _deliveryPoint = null;
        _fromPoint = null;
        _intermediatePoints.clear();
        _descriptionController.clear();
      } else {
        _pollShipment(id);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        error: e,
        message: friendlyErrorMessage(
          e,
          fallback: 'Не удалось изменить статус заказа',
        ),
      );
    } finally {
      if (mounted) setState(() => _cancellingShipment = false);
    }
  }

  /// Создаёт заказ. Возвращает текст ошибки или `null` при успехе.
  ///
  /// Формат запроса не изменён: `title`, `service_type`, `description`,
  /// `stops`, `return_to_start`.
  Future<String?> _createShipment(List<DeliveryPoint> stops) async {
    if (_creatingShipment) return null;
    if (stops.isEmpty) return 'Маршрут не заполнен';
    if (stops.length < 2) return 'Укажите начальную и конечную точки';

    if (!_config.allowsIntermediateStops && stops.length != 2) {
      return '${_config.title}: нужен маршрут ровно из двух точек';
    }

    if (_config.requiresDescription &&
        _descriptionController.text.trim().isEmpty) {
      return 'Опишите пожертвование, чтобы оформить аманат';
    }

    // Сервер требует координаты у каждой точки — без них будет 400.
    if (stops.any((s) => s.lat == null || s.lon == null)) {
      return 'Для каждой точки выберите контейнер из справочника '
          'или место на карте';
    }

    setState(() => _creatingShipment = true);

    try {
      final repo = ShipmentsRepository();
      final title = stops.length > 1 ? stops.last.title : _config.title;

      final shipmentId = await repo.createShipment(
        title: title,
        description: _config.supportsDescription
            ? _descriptionController.text.trim()
            : '',
        stops: stops.map((s) => s.toStopJson()).toList(),
        returnToStart: false,
        serviceType: _config.type,
      );

      if (!mounted) return null;

      setState(() {
        _activeShipmentId = shipmentId;
        // Новый заказ ещё не оплачен. Оплата станет доступна только после
        // того, как backend вернёт awaiting_payment.
        _isPaid = false;
        _currentStatusCode = 'pending';
      });
      _startShipmentPolling(shipmentId);
      return null;
    } catch (e) {
      return friendlyErrorMessage(
        e,
        fallback: 'Не удалось создать заказ. Попробуйте ещё раз.',
      );
    } finally {
      if (mounted) setState(() => _creatingShipment = false);
    }
  }

  Future<void> _submitOrder(List<DeliveryPoint> stops) async {
    FocusScope.of(context).unfocus();
    setState(() => _panelError = null);

    // Итоговая карточка перед отправкой: маршрут, сервис, стоимость.
    // Кнопка внутри неё блокируется на время запроса, поэтому дубликаты
    // заказа создать нельзя.
    await showAppBottomSheet<bool>(
      context: context,
      isDismissible: !_creatingShipment,
      builder: (_) => OrderSummarySheet(
        config: _config,
        stops: stops,
        description: _descriptionController.text,
        onConfirm: () => _createShipment(stops),
      ),
    );
  }

  List<DeliveryPoint> _buildStops({
    required String fromTitle,
    String? bazarTitle,
    String? detailText,
  }) {
    final stops = <DeliveryPoint>[];

    final startFallbackTitle = (detailText != null && detailText.isNotEmpty)
        ? detailText
        : fromTitle;

    final startPoint = _fromPoint != null
        ? DeliveryPoint(
            title: _fromPoint!.title,
            subtitle: _fromPoint!.subtitle,
            lat: _fromPoint!.lat,
            lon: _fromPoint!.lon,
            bazar: _fromPoint!.bazar,
            passage: _fromPoint!.passage,
            container: _fromPoint!.container,
            q: _fromPoint!.q,
          )
        : DeliveryPoint(
            title: startFallbackTitle,
            subtitle: bazarTitle ?? '',
            lat: _myLat,
            lon: _myLon,
            bazar: '',
            passage: '',
            container: '',
            q: '',
          );

    stops.add(startPoint);
    if (_config.allowsIntermediateStops) {
      stops.addAll(_intermediatePoints);
    }
    if (_deliveryPoint != null) stops.add(_deliveryPoint!);

    return stops;
  }

  // --- build ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final rawBottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final bottomInsets = rawBottomInset < 16 ? 16.0 : rawBottomInset;
    final horizontal = AppResponsive.horizontalPadding(context);

    final addressProvider = context.watch<DeliveryAddressProvider>();
    final gpsAddress = addressProvider.gpsHereAddress;
    final gpsLoading = addressProvider.gpsLoading;
    final gpsError = addressProvider.gpsError;

    String fromTitle;
    String? bazarTitle;
    String? detailText;

    if (gpsLoading || _gate == _LocationGate.checking) {
      fromTitle = 'Определяем адрес…';
    } else if (gpsError != null && gpsError.isNotEmpty) {
      fromTitle = 'Не удалось получить адрес';
    } else if (gpsAddress == null || gpsAddress.isEmpty) {
      fromTitle = 'Адрес не найден';
    } else {
      final parsed = parseAddressForUi(gpsAddress);
      fromTitle = parsed.fullAfterCity.isNotEmpty
          ? parsed.fullAfterCity
          : gpsAddress;
      bazarTitle = parsed.marketTitle;
      detailText = parsed.detail;
    }

    final fromTileTitle = _fromPoint?.title ?? fromTitle;
    final showContainerLabels = _zoom >= _containerLabelMinZoom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildMap(
            gpsAddress: gpsAddress,
            gpsLoading: gpsLoading,
            gpsError: gpsError,
            bazarTitle: bazarTitle,
            detailText: detailText,
            showContainerLabels: showContainerLabels,
          ),

          // Верхняя строка: назад, название сервиса, индикатор контейнеров.
          Positioned(
            top: topInset + AppSpacing.xs,
            left: horizontal,
            right: horizontal,
            child: _MapTopBar(
              config: _config,
              containersLoading: _containersLoading,
              containersCount: _visibleContainers.length,
              onBack: () => context.go('/home'),
              onContainers: _focusContainers,
              showContainers: SafaMobileMapFeatures.backendDrawingLayersEnabled,
            ),
          ),

          // Кнопка «моя геолокация» — плавно следует за нижней панелью.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            right: horizontal,
            bottom: _activeShipmentId != null
                ? 300 + bottomInsets
                : (_orderPanelCollapsed
                    ? 86 + bottomInsets
                    : (_searchMode ? 320 + bottomInsets : 360 + bottomInsets)),
            child: AppMapActionButton(
              icon: Icons.my_location_rounded,
              semanticLabel: 'Моё местоположение',
              loading: _gate == _LocationGate.checking,
              onTap: _goToMyLocation,
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(
              fromTitle: fromTitle,
              fromTileTitle: fromTileTitle,
              bazarTitle: bazarTitle,
              detailText: detailText,
              horizontal: horizontal,
              bottomInsets: bottomInsets,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap({
    required String? gpsAddress,
    required bool gpsLoading,
    required String? gpsError,
    required String? bazarTitle,
    required String? detailText,
    required bool showContainerLabels,
  }) {
    final markers = <SafaMapMarker>[];
    final containerPolygons = <Polygon>[];
    final marketMap = SafaMobileMapFeatures.backendDrawingLayersEnabled
        ? _marketMapRenderData()
        : MarketMapRenderData.empty;
    final publishedContainerIds =
        SafaMobileMapFeatures.backendDrawingLayersEnabled
        ? _publishedContainerIds()
        : const <int>{};
    final renderedLooseContainers =
        SafaMobileMapFeatures.backendDrawingLayersEnabled
        ? _renderedLooseContainers(
            publishedContainerIds,
            hideWhenPublishedContainersVisible: marketMap.hasRenderedContainers,
          )
        : const <ContainerRef>[];
    final shouldDrawLooseContainerShapes =
        _zoom >= _containerShapeMinZoom &&
        (renderedLooseContainers.length <= _maxRenderedLooseContainers ||
            _zoom >= _containerLabelMinZoom);
    final showLooseContainerLabels =
        showContainerLabels &&
        renderedLooseContainers.length <= _maxRenderedContainerLabels;

    for (final feature in _renderedMarketMapContainerFeatures()) {
      if (!feature.isContainer ||
          feature.minZoom > _zoom ||
          _zoom < _containerShapeMinZoom) {
        continue;
      }
      final lat = feature.centerLat;
      final lon = feature.centerLon;
      final center = lat != null && lon != null
          ? LatLng(lat, lon)
          : _featureCenter(feature.coordinates);
      if (center == null) continue;
      markers.add(
        SafaMapMarker(
          id: 'published-container-${feature.id}',
          point: center,
          width: 48,
          height: 48,
          alignment: Alignment.center,
          onTap: () => _onMarketMapContainerTapped(feature),
          child: const SizedBox.expand(),
        ),
      );
    }

    for (final container in renderedLooseContainers) {
      final lat = container.latValue;
      final lon = container.lonValue;
      if (lat == null || lon == null) continue;

      final selected = _selectedContainer?.id == container.id;

      if (selected || shouldDrawLooseContainerShapes) {
        containerPolygons.add(
          Polygon(
            points: _containerPolygonPoints(lat, lon),
            color: selected
                ? AppColors.primary.withValues(alpha: 0.16)
                : AppColors.white.withValues(alpha: 0.2),
            borderColor: selected ? AppColors.primary : AppColors.textPrimary,
            borderStrokeWidth: selected ? 2.2 : 1.2,
          ),
        );
      }

      markers.add(
        SafaMapMarker(
          id: 'container-${container.id}',
          point: LatLng(lat, lon),
          width: ContainerMapMarker.hitSize,
          height: ContainerMapMarker.hitSize,
          alignment: Alignment.center,
          onTap: () => _onContainerTapped(container),
          visualKey: '$selected-$showLooseContainerLabels-${container.number}',
          child: ContainerMapMarker(
            container: container,
            selected: selected,
            showLabel: showLooseContainerLabels,
          ),
        ),
      );
    }

    if (!_searchMode) {
      markers.add(
        SafaMapMarker(
          id: 'my-location',
          point: LatLng(_myLat, _myLon),
          width: 220,
          height: 120,
          alignment: Alignment.topCenter,
          visualKey:
              '$gpsAddress-$gpsLoading-$gpsError-$bazarTitle-$detailText',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HereBubble(
                address: gpsAddress,
                loading: gpsLoading || _gate == _LocationGate.checking,
                error: gpsError,
                marketTitle: bazarTitle,
                detail: detailText,
              ),
              AppSpacing.gapXs,
              const MeDot(),
            ],
          ),
        ),
      );
    } else {
      final pts = _spreadSamePoints(_extractStopPoints(_activeStops));
      for (int i = 0; i < pts.length; i++) {
        markers.add(
          SafaMapMarker(
            id: 'active-stop-$i',
            point: pts[i],
            width: 32,
            height: 32,
            alignment: Alignment.center,
            visualKey: '${i == 0}-${i == pts.length - 1}',
            child: _StopDotMarker(
              index: i + 1,
              isFirst: i == 0,
              isLast: i == pts.length - 1,
            ),
          ),
        );
      }

      final courierPosition = _courierPosition;
      if (courierPosition != null) {
        final updatedAt = _courierPositionUpdatedAt;
        final isStale =
            updatedAt != null &&
            DateTime.now().toUtc().difference(updatedAt.toUtc()) >
                const Duration(minutes: 2);
        markers.add(
          SafaMapMarker(
            id: 'courier-live',
            point: courierPosition,
            width: 112,
            height: 68,
            alignment: Alignment.bottomCenter,
            visualKey: '$isStale',
            child: _CourierTrackingMarker(isStale: isStale),
          ),
        );
      }
    }

    return SafaYandexMap(
      controller: _mapController,
      initialCenter: LatLng(_centerLat, _centerLon),
      initialZoom: 15,
      onPositionChanged: (pos, hasGesture) {
        final c = pos.center;
        _centerLat = c.latitude;
        _centerLon = c.longitude;
        if (hasGesture) {
          _setMapMoving(true);
          _scheduleMapIdle();
        }

        // Перерисовываем экран только при переходе через порог масштаба,
        // из которого зависит видимость подписей контейнеров, — жест
        // панорамирования сам по себе setState не вызывает.
        final wasLabelled = _zoom >= _containerLabelMinZoom;
        final oldZoomBucket = _zoom.floor();
        final isLabelled = pos.zoom >= _containerLabelMinZoom;
        final newZoomBucket = pos.zoom.floor();
        _zoom = pos.zoom;
        if ((wasLabelled != isLabelled || oldZoomBucket != newZoomBucket) &&
            mounted) {
          setState(() {});
        }

        if (!hasGesture) {
          _scheduleContainersRefresh();
          _scheduleMarketMapRefresh();
        }
      },
      polygons: [...marketMap.polygons, ...containerPolygons],
      polylines: [
        ...marketMap.polylines,
        if (_routePoints.isNotEmpty) ...[
          Polyline(
            points: _routePoints,
            strokeWidth: 6,
            color: AppColors.routeLineHalo,
          ),
          Polyline(
            points: _routePoints,
            strokeWidth: 3.5,
            color: AppColors.primary,
          ),
        ],
      ],
      markers: [...marketMap.markers, ...markers],
    );
  }

  List<LatLng> _containerPolygonPoints(double lat, double lon) {
    const dLat = 0.000055;
    const dLon = 0.000075;

    return [
      LatLng(lat - dLat, lon - dLon),
      LatLng(lat - dLat, lon + dLon),
      LatLng(lat + dLat, lon + dLon),
      LatLng(lat + dLat, lon - dLon),
    ];
  }

  List<ContainerRef> _renderedLooseContainers(
    Set<int> publishedContainerIds, {
    required bool hideWhenPublishedContainersVisible,
  }) {
    if (_mapMoving && _selectedContainer == null) return const [];
    if (hideWhenPublishedContainersVisible) {
      return const [];
    }
    final selected = _selectedContainer;
    final center = LatLng(_centerLat, _centerLon);
    final candidates = _visibleContainers
        .where(
          (container) =>
              !publishedContainerIds.contains(container.id) &&
              container.latValue != null &&
              container.lonValue != null,
        )
        .toList();

    final sorted = candidates.map((container) {
      final lat = container.latValue;
      final lon = container.lonValue;
      if (lat == null || lon == null) {
        return MapEntry(container, double.infinity);
      }
      final dLat = lat - center.latitude;
      final dLon = lon - center.longitude;
      return MapEntry(container, dLat * dLat + dLon * dLon);
    }).toList();

    sorted.sort((a, b) {
      if (selected != null) {
        if (a.key.id == selected.id) return -1;
        if (b.key.id == selected.id) return 1;
      }
      return a.value.compareTo(b.value);
    });

    final limited = sorted.length <= _maxRenderedContainerMarkers
        ? sorted
        : sorted.take(_maxRenderedContainerMarkers);
    return limited.map((entry) => entry.key).toList();
  }

  Widget _buildBottomPanel({
    required String fromTitle,
    required String fromTileTitle,
    required String? bazarTitle,
    required String? detailText,
    required double horizontal,
    required double bottomInsets,
  }) {
    if (_activeShipmentId == null) {
      return ServiceOrderPanel(
        config: _config,
        fromTitle: fromTileTitle,
        fromSubtitle: _fromPoint?.subtitle ?? bazarTitle,
        fromIsSelected: _fromPoint != null,
        destination: _deliveryPoint,
        intermediatePoints: _intermediatePoints,
        descriptionController: _descriptionController,
        creating: _creatingShipment,
        errorMessage: _panelError,
        onCollapseChanged: (c) {
          if (_orderPanelCollapsed != c) {
            setState(() => _orderPanelCollapsed = c);
          }
        },
        onEditFrom: () =>
            _editFromPoint(fromTitle: fromTitle, bazarTitle: bazarTitle),
        onEditDestination: _editDestination,
        onEditIntermediate: _editIntermediatePoint,
        onAddIntermediate: _addIntermediatePoint,
        onRemoveIntermediate: _removeIntermediatePoint,
        onReorderIntermediate: _reorderIntermediatePoints,
        onSubmit: () => _submitOrder(
          _buildStops(
            fromTitle: fromTitle,
            bazarTitle: bazarTitle,
            detailText: detailText,
          ),
        ),
      );
    }

    final Widget panel;
    if (_showFulfillmentSheet) {
      panel = OrderFulfillmentSheet(
        stops: _activeStops,
        statusCode: _currentStatusCode,
        carrierFirstName: _carrierFirstName,
        carrierPhone: _carrierPhone,
        carrierAvatarUrl: _carrierAvatarUrl,
        carrierSpecialistType: _carrierSpecialistType,
      );
    } else if (_currentStatus == ShipmentStatus.awaitingPayment && !_isPaid) {
      final shipmentId = _activeShipmentId!;
      panel = ShipmentPaymentSheet(
        shipmentId: shipmentId,
        amount: _fare,
        onPaymentConfirmed: () => _refreshShipmentAfterPayment(shipmentId),
      );
    } else {
      panel = SearchingSheet(
        stops: _activeStops.isNotEmpty
            ? _activeStops
            : _buildStops(
                fromTitle: fromTitle,
                bazarTitle: bazarTitle,
                detailText: detailText,
              ),
        cancelling: _cancellingShipment,
        onCancel: _cancelShipment,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        0,
        horizontal,
        AppSpacing.md + bottomInsets,
      ),
      child: panel,
    );
  }
}

class _MapTopBar extends StatelessWidget {
  const _MapTopBar({
    required this.config,
    required this.containersLoading,
    required this.containersCount,
    required this.onBack,
    required this.onContainers,
    this.showContainers = true,
  });

  final ServiceConfig config;
  final bool containersLoading;
  final int containersCount;
  final VoidCallback onBack;
  final VoidCallback onContainers;
  final bool showContainers;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppMapActionButton(
          icon: Icons.arrow_back_ios_new_rounded,
          semanticLabel: 'Назад',
          onTap: onBack,
        ),
        AppSpacing.hGapXs,
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.allSm,
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.raised,
            ),
            child: Row(
              children: [
                Icon(config.icon, size: 18, color: config.accent),
                AppSpacing.hGapXs,
                Expanded(
                  child: Text(
                    config.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardTitle,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showContainers) ...[
          AppSpacing.hGapXs,
          AppMapActionButton(
            icon: Icons.grid_view_rounded,
            semanticLabel: containersLoading
                ? 'Загружаем контейнеры'
                : 'Показать контейнеры: $containersCount',
            loading: containersLoading,
            badgeColor: containersCount > 0 ? AppColors.container : null,
            onTap: onContainers,
          ),
        ],
      ],
    );
  }
}

/// Маркер точки маршрута активного заказа.
class _StopDotMarker extends StatelessWidget {
  const _StopDotMarker({
    required this.index,
    required this.isFirst,
    required this.isLast,
  });

  final int index;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = isFirst
        ? AppColors.success
        : isLast
        ? AppColors.primary
        : AppColors.info;

    return Semantics(
      label: isFirst
          ? 'Начальная точка'
          : isLast
          ? 'Конечная точка'
          : 'Остановка $index',
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 2.5),
          boxShadow: AppShadows.raised,
        ),
        child: Text(
          '$index',
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 11,
            height: 1,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}

class _CourierTrackingMarker extends StatelessWidget {
  const _CourierTrackingMarker({required this.isStale});

  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final color = isStale ? AppColors.textSecondary : AppColors.primary;
    return Semantics(
      label: isStale
          ? 'Последняя известная позиция специалиста'
          : 'Специалист движется к заказу',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppShadows.raised,
            ),
            child: Text(
              isStale ? 'Последняя позиция' : 'Специалист',
              maxLines: 1,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 10,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 3),
              boxShadow: AppShadows.raised,
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              size: 20,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
