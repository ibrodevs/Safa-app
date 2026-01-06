import 'dart:async';

import 'package:dogo/features/main_module/map/provider/delivery_address_provider.dart';
import 'package:dogo/features/main_module/map/view/components/deliveri_point_sheet.dart';
import 'package:dogo/features/main_module/map/view/widgets/input_tile.dart';
import 'package:dogo/features/main_module/map/view/components/search_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/app_colors.dart';
import '../../../../data/network/api_service.dart';
import '../../type_cargo/view/cargo_type_screen.dart';
import '../data/model/delivery_point_model.dart';
import '../data/model/shipment_status.dart';
import '../provider/active_shipment_provider.dart';
import 'components/from_point_sheet.dart';
import 'components/order_fulfillment_sheet.dart';
import 'widgets/add_adress_button.dart';
import 'widgets/here_bubble.dart';
import 'components/intermediate_point_sheet.dart';
import 'widgets/me_dot.dart';
import 'widgets/parsed_adress.dart';

class OrderMapScreen extends StatefulWidget {
  const OrderMapScreen({super.key});

  @override
  State<OrderMapScreen> createState() => _OrderMapScreenState();
}

enum _LocationGate { checking, ready, denied, serviceOff }

class _OrderMapScreenState extends State<OrderMapScreen> {
  double _myLat = 42.8746;
  double _myLon = 74.6122;

  double _centerLat = 42.8746;
  double _centerLon = 74.6122;

  final MapController _mapController = MapController();

  DeliveryPoint? _deliveryPoint;
  DeliveryPoint? _fromPoint;
  final List<DeliveryPoint> _intermediatePoints = [];

  int? _activeShipmentId;
  bool _creatingShipment = false;
  bool _cancellingShipment = false;

  bool get _searchMode => _activeShipmentId != null;
  bool _showFulfillmentSheet = false;
  bool _bootstrappedActive = false;
  List<DeliveryPoint> _activeStops = const [];
  bool _didInitialMove = false;
  _LocationGate _gate = _LocationGate.checking;

  Timer? _shipmentPollTimer;
  ShipmentStatus _currentStatus = ShipmentStatus.unknown;

  @override
  void initState() {
    super.initState();
    _initLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final p = context.read<ActiveShipmentProvider>();
      await p.load();
      if (!mounted) return;

      final active = p.active;
      if (active == null) return;

      if (_activeShipmentId != null) return;

      if (_bootstrappedActive) return;
      _bootstrappedActive = true;

      final st = active.status.toLowerCase();
      final showFulfillment = st == 'in_transit';
      setState(() {
        _activeShipmentId = active.id;
        _activeStops = active.stops;
      });
      _startShipmentPolling(active.id);

    });
  }
  @override
  void dispose() {
    _stopShipmentPolling();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final addressProvider = context.read<DeliveryAddressProvider>();

    try {
      if (mounted) {
        setState(() => _gate = _LocationGate.checking);
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _gate = _LocationGate.serviceOff);
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _gate = _LocationGate.denied);
        return;
      }

      if (perm != LocationPermission.always &&
          perm != LocationPermission.whileInUse) {
        if (mounted) setState(() => _gate = _LocationGate.denied);
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
        _gate = _LocationGate.ready;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_gate != _LocationGate.ready) return;
        if (_didInitialMove) return;
        _didInitialMove = true;

        _mapController.move(LatLng(_myLat, _myLon), 15);
      });

      await addressProvider.fetchGpsHereAddress(lat: _myLat, lon: _myLon);
    } catch (e, st) {
      debugPrint('initLocation error: $e\n$st');
      if (mounted) {
        setState(() => _gate = _LocationGate.denied);
      }
    }

  }

  void _stopShipmentPolling() {
    _shipmentPollTimer?.cancel();
    _shipmentPollTimer = null;
  }
  void _resetShipmentState() {
    setState(() {
      _activeShipmentId = null;
      _showFulfillmentSheet = false;
      _activeStops = const [];
      _currentStatus = ShipmentStatus.unknown;
      _bootstrappedActive = false;
    });

    context.read<ActiveShipmentProvider>().clear();
  }

  Future<void> _pollShipment(int shipmentId) async {
    try {
      final dto = await context
          .read<ActiveShipmentProvider>()
          .getById(shipmentId);

      if (!mounted) return;

      final status = parseShipmentStatus(dto.status);

      if (status == _currentStatus) return;

      _currentStatus = status;

      if (status == ShipmentStatus.completed ||
          status == ShipmentStatus.canceled) {
        _stopShipmentPolling();
        _resetShipmentState();
        return;
      }

      setState(() {
        _activeStops = dto.stops;
        _showFulfillmentSheet =
            status == ShipmentStatus.assigned ||
                status == ShipmentStatus.inTransit;
      });
    } catch (_) {
    }
  }

  void _startShipmentPolling(int shipmentId) {
    _shipmentPollTimer?.cancel();

    _shipmentPollTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _pollShipment(shipmentId),
    );

    _pollShipment(shipmentId);
  }

  Future<void> _openIntermediatePointSheet() async {
    final result = await showModalBottomSheet<DeliveryPoint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        final bottom = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: IntermediatePointSheet(
            addressLine: 'Промежуточная точка',
            placeLine: 'Заполните поля ниже',
            lat: _centerLat,
            lon: _centerLon,
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _intermediatePoints.add(result));
    }
  }

  Future<void> _openDeliveryPointSheet() async {
    final addr = context.read<DeliveryAddressProvider>().fromAddress;

    final result = await showModalBottomSheet<DeliveryPoint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeliveryPointSheet(
        mainTitle: 'Точка доставки',
        bazarTitle: addr,
        lat: _centerLat,
        lon: _centerLon,
      ),
    );

    if (result != null && mounted) {
      setState(() => _deliveryPoint = result);
    }
  }

  Future<void> _openFromPointSheet({
    required String fromTitle,
    String? bazarTitle,
  }) async {
    final result = await showModalBottomSheet<DeliveryPoint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FromPointSheet(
        mainTitle: fromTitle,
        bazarTitle: bazarTitle,
        lat: _myLat,
        lon: _myLon,
        subtitle: bazarTitle ?? '',
      ),
    );

    if (result != null && mounted) {
      setState(() => _fromPoint = result);
    }
  }

  Future<void> _cancelShipment() async {
    final id = _activeShipmentId;
    if (id == null || _cancellingShipment) return;

    setState(() => _cancellingShipment = true);

    try {
      _stopShipmentPolling();

      await ApiService.instance.patchShipmentStatus(id, status: 'canceled');

      if (!mounted) return;

      _resetShipmentState();
      _deliveryPoint = null;
      _fromPoint = null;
      _intermediatePoints.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _cancellingShipment = false);
    }
  }


  List<DeliveryPoint> _buildStopsForSearchSheet({
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
    stops.addAll(_intermediatePoints);
    if (_deliveryPoint != null) stops.add(_deliveryPoint!);

    return stops;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInsets = MediaQuery.viewPaddingOf(context).bottom;
    final isMapAllowed = _gate == _LocationGate.ready;
    if (_gate == _LocationGate.checking) {
      return const Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final addressProvider = context.watch<DeliveryAddressProvider>();

    final gpsAddress = addressProvider.gpsHereAddress;
    final gpsLoading = addressProvider.gpsLoading;
    final gpsError = addressProvider.gpsError;

    String fromTitle;
    String? bazarTitle;
    String? detailText;

    if (gpsLoading) {
      fromTitle = 'Определяем адрес...';
    } else if (gpsAddress == null || gpsAddress.isEmpty) {
      fromTitle = 'Определяем адрес...';
    } else {
      final parsed = parseAddressForUi(gpsAddress);
      fromTitle = parsed.fullAfterCity.isNotEmpty
          ? parsed.fullAfterCity
          : gpsAddress;
      bazarTitle = parsed.marketTitle;
      detailText = parsed.detail;
    }

    final fromTileTitle = _fromPoint?.title ?? fromTitle;
    final myPoint = LatLng(_myLat, _myLon);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          if (_gate == _LocationGate.ready)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_centerLat, _centerLon),
                initialZoom: 15,
                onPositionChanged: (pos, hasGesture) {
                  final c = pos.center;
                  _centerLat = c.latitude;
                  _centerLon = c.longitude;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'kg.genesis.dogo',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: myPoint,
                      width: 220,
                      height: 140,
                      alignment: Alignment.center,
                      child: Transform.translate(
                        offset: const Offset(0, -55),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HereBubble(
                              address: gpsAddress,
                              loading: gpsLoading,
                              error: gpsError,
                              marketTitle: bazarTitle,
                              detail: detailText,
                            ),
                            const SizedBox(height: 8),
                            const MeDot(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            const SizedBox.expand(),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + bottomInsets,
            child: _activeShipmentId != null
                ? (_showFulfillmentSheet
                      ? const OrderFulfillmentSheet()
                      : SearchingSheet(
                          stops: _activeStops.isNotEmpty
                              ? _activeStops
                              : _buildStopsForSearchSheet(
                                  fromTitle: fromTitle,
                                  bazarTitle: bazarTitle,
                                  detailText: detailText,
                                ),
                          cancelling: _cancellingShipment,
                          onCancel: _cancelShipment,
                        ))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InputTile(
                        iconAsset: 'assets/icons/ic_box.svg',
                        title: fromTileTitle,
                        enabled: true,
                        onTap: () => _openFromPointSheet(
                          fromTitle: fromTitle,
                          bazarTitle: bazarTitle,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: InputTile(
                              iconAsset: 'assets/icons/ic_box.svg',
                              title: _deliveryPoint?.title ?? 'Куда доставить',
                              enabled: _deliveryPoint != null,
                              onTap: _openDeliveryPointSheet,
                            ),
                          ),
                          const SizedBox(width: 10),
                          AddAddressButton(onTap: _openIntermediatePointSheet),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              (_deliveryPoint == null || _creatingShipment)
                              ? null
                              : () async {
                                  final stops = _buildStopsForSearchSheet(
                                    fromTitle: fromTitle,
                                    bazarTitle: bazarTitle,
                                    detailText: detailText,
                                  );

                                  final result = await context
                                      .push<CargoTypePaidResult>(
                                        '/type_cargo',
                                        extra: CargoRouteArgs(stops: stops),
                                      );

                                  if (result != null && mounted) {
                                    setState(
                                      () =>
                                          _activeShipmentId = result.shipmentId,
                                    );
                                  }
                                },
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith(
                              (_) => AppColors.accent,
                            ),
                            foregroundColor: WidgetStateProperty.resolveWith(
                              (_) => Colors.white,
                            ),
                            overlayColor: WidgetStateProperty.resolveWith(
                              (_) => Colors.white.withOpacity(0.10),
                            ),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            textStyle: WidgetStateProperty.all(
                              const TextStyle(
                                fontSize: 18,
                                fontFamily: 'SFProText',
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          child: Text(
                            _creatingShipment ? 'Создаём заказ…' : 'Далее',
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
