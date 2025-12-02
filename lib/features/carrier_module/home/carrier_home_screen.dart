import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../data/network/api_service.dart';
import '../../../data/notifications/service/push_service.dart';
import 'data/model/nearby_shipments.dart';

class CarrierHomeScreen extends StatefulWidget {
  const CarrierHomeScreen({super.key});

  @override
  State<CarrierHomeScreen> createState() => _CarrierHomeScreenState();
}

class _CarrierHomeScreenState extends State<CarrierHomeScreen> {
  static const _accent = Color(0xFFFF8A00);
  static const _titleBlack = Color(0xFF000000);
  static const _greyText = Color(0xFF9FA4AD);

 /* final ykit.Point _bishkekCenter = const ykit.Point(
    latitude: 42.8746,
    longitude: 74.6122,
  );*/

/*
  ykit.MapWindow? _mapWindow;
  late final RoutingService _routing;
*/

  bool _loadingOnline = false;
  bool _showWelcome = true;

  NearbyShipment? _currentShipment;
  List<NearbyShipment> _shipments = const [];

  bool _routeLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      PushService.instance.registerOnServerOnce(kind: 'carrier');
    });
  }
 /* @override
  void initState() {
    super.initState();
    mapkit.onStart();
    _routing = RoutingService(ApiService.instance.dio);
  }

  @override
  void dispose() {
    mapkit.onStop();
    super.dispose();
  }
*/
 /* void _onMapCreated(ykit.MapWindow mapWindow) {
    _mapWindow = mapWindow;
    final map = mapWindow.map;
    map.move(
      ykit.CameraPosition(
        _bishkekCenter,
        zoom: 14.0,
        azimuth: 0.0,
        tilt: 0.0,
      ),
    );
  }*/

  Future<void> _goOnline() async {
    if (_loadingOnline) return;
    setState(() {
      _loadingOnline = true;
    });

    try {
      final pos = await _getCurrentPosition();

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
          _loadingOnline = false;
          _showWelcome = true;
        });
        return;
      }

      _shipments = page.results;
      _currentShipment = _shipments.first;
      _showWelcome = false;

      /*await _showShipmentOnMap(_currentShipment!);*/
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingOnline = false;
        });
      }
    }
  }

  Future<Position> _getCurrentPosition() async {
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Службы геолокации выключены');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Нет доступа к геолокации');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

 /* Future<void> _showShipmentOnMap(NearbyShipment shipment) async {
    if (_mapWindow == null || shipment.stops.isEmpty) return;

    setState(() {
      _routeLoading = true;
    });

    try {
      final stopsPoints = shipment.stops
          .map(
            (s) => ykit.Point(latitude: s.lat, longitude: s.lon),
      )
          .toList();

      final polylinePoints =
      await _routing.buildWalkingRoute(stopsPoints);

      if (!mounted) return;

      _updateRouteObjects(
        polylinePoints: polylinePoints,
        stops: stopsPoints,
      );

      final firstPoint = stopsPoints.first;
      _mapWindow!.map.move(
        ykit.CameraPosition(firstPoint, zoom: 17, azimuth: 0, tilt: 0),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось построить маршрут: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _routeLoading = false;
        });
      }
    }
  }

  void _updateRouteObjects({
    required List<ykit.Point> polylinePoints,
    required List<ykit.Point> stops,
  }) {
    final map = _mapWindow?.map;
    if (map == null) return;

    final objects = map.mapObjects;

    objects.clear();

    if (polylinePoints.length >= 2) {
      final polyline = objects.addPolyline();
      polyline.geometry = ykit.Polyline(polylinePoints);
      polyline.strokeWidth = 4;
      polyline.outlineColor = Colors.white;
    }

    for (final p in stops) {
      final circle = objects.addCircle(ykit.Circle as ykit.Circle);
      circle.geometry = ykit.Circle(
        p,
        radius: 8,
      );
      circle.strokeWidth = 3;
      circle.strokeColor = const Color(0xFFFFD2A7);
      circle.fillColor = const Color(0xFFFFE3C4);
    }
  }


  void _rejectCurrent() {
    if (_shipments.isEmpty || _currentShipment == null) return;

    final idx = _shipments.indexOf(_currentShipment!);
    if (idx + 1 < _shipments.length) {
      setState(() {
        _currentShipment = _shipments[idx + 1];
      });
      _showShipmentOnMap(_currentShipment!);
    } else {
      setState(() {
        _currentShipment = null;
        _shipments = const [];
        _showWelcome = true;
      });
      final map = _mapWindow?.map;
      map?.mapObjects.clear();
      if (map != null) {
        map.move(
          ykit.CameraPosition(_bishkekCenter, zoom: 14, azimuth: 0, tilt: 0),
        );
      }
    }
  }

  void _acceptCurrent() {
    if (_currentShipment == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Заказ ${_currentShipment!.publicCode} принят'),
      ),
    );
  }
*/
  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final padding = MediaQuery.viewPaddingOf(context);
    final bottomSafe = padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [

          if (_showWelcome)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  bottomSafe + viewInsets.bottom + 12,
                ),
                child: _WelcomeCard(
                  loading: _loadingOnline,
                  onTap: _goOnline,
                ),
              ),
            ),

          if (!_showWelcome && _currentShipment != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  bottomSafe + viewInsets.bottom + 12,
                ),
                // child: _ShipmentSheet(
                //   shipment: _currentShipment!,
                //   accent: _accent,
                //   routeLoading: _routeLoading,
                //   onAccept: _acceptCurrent,
                //   onReject: _rejectCurrent,
                // ),
                child: SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}


class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.loading,
    required this.onTap,
  });

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A000000),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
            'Сатурн — шестая планета по удалённости от Солнца и вторая по размерам планета',
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
    final distanceText =
    distance >= 1000 ? '${(distance / 1000).toStringAsFixed(1)} км' : '$distance метров';

    final stopsCount = shipment.stops.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0x26000000),
            blurRadius: 18,
            offset: const Offset(0, -4),
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
            'Ближайшая подача: ${shipment.stops.first.title}',
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
              _Chip(
                icon: Icons.inventory_2_outlined,
                label: 'Большие мешки',
              ),
              const SizedBox(width: 8),
              _Chip(
                icon: Icons.map_outlined,
                label: '$stopsCount точки',
              ),
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
              Icon(
                Icons.add,
                size: 16,
                color: Color(0xFF22C55E),
              ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Забрать заказ',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
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
                style: TextStyle(
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.3,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFFFF8A00),
          ),
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
