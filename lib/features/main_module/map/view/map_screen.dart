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
import '../../type_cargo/view/cargo_type_screen.dart'
    show CargoTypeResult, CargoRouteArgs;
import '../../../../data/network/api_service.dart';
import '../../type_cargo/view/cargo_type_screen.dart';
import '../data/model/delivery_point_model.dart';
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

class _OrderMapScreenState extends State<OrderMapScreen> {
  double _myLat = 42.8746;
  double _myLon = 74.6122;

  double _centerLat = 42.8746;
  double _centerLon = 74.6122;

  final MapController _mapController = MapController();

  DeliveryPoint? _deliveryPoint;
  final List<DeliveryPoint> _intermediatePoints = [];

  int? _activeShipmentId;
  bool _creatingShipment = false;
  bool _cancellingShipment = false;

  bool get _searchMode => _activeShipmentId != null;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final addressProvider = context.read<DeliveryAddressProvider>();
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location service disabled');
        await addressProvider.fetchGpsHereAddress(lat: _myLat, lon: _myLon);
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        debugPrint('Location permission deniedForever');
        await addressProvider.fetchGpsHereAddress(lat: _myLat, lon: _myLon);
        return;
      }
      if (perm != LocationPermission.always &&
          perm != LocationPermission.whileInUse) {
        debugPrint('Location permission not granted: $perm');
        await addressProvider.fetchGpsHereAddress(lat: _myLat, lon: _myLon);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _myLat = pos.latitude;
        _myLon = pos.longitude;
        _centerLat = _mymyLatFallback(_myLat);
        _centerLon = _myLon;
      });

      _mapController.move(LatLng(_myLat, _myLon), 15);

      await addressProvider.fetchGpsHereAddress(lat: _myLat, lon: _myLon);

      debugPrint('Location OK: $_myLat, $_myLon');
    } catch (e, st) {
      debugPrint('initLocation error: $e\n$st');
      if (mounted) {
        await addressProvider.fetchGpsHereAddress(lat: _myLat, lon: _myLon);
      }
    }
  }

  double _mymyLatFallback(double v) => (v.isNaN || v.isInfinite) ? 42.8746 : v;

  Future<void> _openIntermediatePointSheet() async {
    final result = await showModalBottomSheet<DeliveryPoint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        final bottom = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: const IntermediatePointSheet(
            addressLine: 'Контейнер 74, 8 проход',
            placeLine: 'Алкан базары',
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _intermediatePoints.add(result);
      });
    }
  }

  Future<void> _openDeliveryPointSheet() async {
    final addr = context.read<DeliveryAddressProvider>().fromAddress;

    final result = await showModalBottomSheet<DeliveryPoint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          DeliveryPointSheet(mainTitle: '...', bazarTitle: addr),
    );

    if (result != null && mounted) {
      setState(() {
        _deliveryPoint = result;
      });
    }
  }

  Future<void> _createShipmentWithCargo(CargoTypeResult cargo) async {
    if (_creatingShipment) return;
    if (_deliveryPoint == null) return;

    final stops = <Map<String, dynamic>>[];

    final addressProvider = context.read<DeliveryAddressProvider>();

    final gpsHere = addressProvider.gpsHereAddress;
    final originTitle = (gpsHere != null && gpsHere.isNotEmpty)
        ? gpsHere
        : 'Мой адрес';

    stops.add({'title': originTitle, 'lat': _myLat, 'lon': _myLon});

    for (final p in _intermediatePoints) {
      stops.add({'title': p.title, 'lat': p.lat, 'lon': p.lon});
    }

    final dest = _deliveryPoint!;
    stops.add({'title': dest.title, 'lat': dest.lat, 'lon': dest.lon});

    setState(() {
      _creatingShipment = true;
    });

    try {
      final json = await ApiService.instance.createShipment(
        title: 'Доставка',
        segment: cargo.segmentId,
        quantity: cargo.quantity,
        stops: stops,
      );

      final id = json['id'] as int?;
      if (id != null) {
        setState(() {
          _activeShipmentId = id;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _creatingShipment = false;
        });
      }
    }
  }

  Future<void> _cancelShipment() async {
    final id = _activeShipmentId;
    if (id == null || _cancellingShipment) return;

    setState(() {
      _cancellingShipment = true;
    });

    try {
      await ApiService.instance.deleteShipment(id);
      setState(() {
        _activeShipmentId = null;
        _deliveryPoint = null;
        _intermediatePoints.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _cancellingShipment = false;
        });
      }
    }
  }

  List<DeliveryPoint> _buildStopsForSearchSheet({
    required String fromTitle,
    String? bazarTitle,
    String? detailText,
  }) {
    final stops = <DeliveryPoint>[];

    final startTitle = (detailText != null && detailText.isNotEmpty)
        ? detailText
        : fromTitle;
    final startSubtitle = bazarTitle ?? '';

    stops.add(
      DeliveryPoint(
        title: startTitle,
        subtitle: startSubtitle,
        lat: _myLat,
        lon: _myLon,
      ),
    );

    stops.addAll(_intermediatePoints);
    if (_deliveryPoint != null) {
      stops.add(_deliveryPoint!);
    }
    return stops;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInsets = MediaQuery.viewPaddingOf(context).bottom;

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

    final myPoint = LatLng(_myLat, _myLon);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
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
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + bottomInsets,
            child: _searchMode
                ? SearchingSheet(
                    stops: _buildStopsForSearchSheet(
                      fromTitle: fromTitle,
                      bazarTitle: bazarTitle,
                      detailText: detailText,
                    ),
                    cancelling: _cancellingShipment,
                    onCancel: _cancelShipment,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InputTile(
                        iconAsset: 'assets/icons/ic_box.svg',
                        title: fromTitle,
                        enabled: true,
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
                                      .push<CargoTypeResult>(
                                        '/type_cargo',
                                        extra: CargoRouteArgs(stops: stops),
                                      );

                                  if (result != null && mounted) {
                                    await _createShipmentWithCargo(result);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              color: AppColors.black,
                              fontFamily: 'SFProText',
                              fontWeight: FontWeight.w800,
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
