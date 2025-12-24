import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../data/network/api_service.dart';
import '../../../data/notifications/service/push_service.dart';
import 'data/model/nearby_shipment.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/network/api_service.dart';
import '../../../data/notifications/service/push_service.dart';
import 'data/model/nearby_shipment.dart';

class CarrierHomeScreen extends StatefulWidget {
  const CarrierHomeScreen({super.key});

  @override
  State<CarrierHomeScreen> createState() => _CarrierHomeScreenState();
}

class _CarrierHomeScreenState extends State<CarrierHomeScreen> {
  static const _accent = Color(0xFFFF8A00);
  static const _titleBlack = Color(0xFF000000);
  static const _greyText = Color(0xFF9FA4AD);

  final LatLng _bishkekCenter = const LatLng(42.8746, 74.6122);

  final MapController _mapController = MapController();

  double _myLat = 42.8746;
  double _myLon = 74.6122;
  double _centerLat = 42.8746;
  double _centerLon = 74.6122;

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
    _initLocation();
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
      if (perm != LocationPermission.always && perm != LocationPermission.whileInUse) {
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

      setState(() {
        _myLat = pos.latitude;
        _myLon = pos.longitude;
        _centerLat = _myLat;
        _centerLon = _myLon;
      });
      _moveMap(LatLng(_myLat, _myLon), zoom: 15);
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
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('Нет доступа к геолокации');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final padding = MediaQuery.viewPaddingOf(context);
    final bottomSafe = padding.bottom;

    final myPoint = LatLng(_myLat, _myLon);

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
              MarkerLayer(
                markers: [
                  Marker(
                    point: myPoint,
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: const _MeDot(),
                  ),
                ],
              ),
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

          if (_showWelcome)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  10,
                  0,
                  10,
                  bottomSafe + viewInsets.bottom + 12,
                ),
                child: _WelcomeCard(loading: _loadingOnline, onTap: _goOnline),
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
                child: SizedBox.shrink(),
              ),
            ),

          Positioned(
            top: padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _showWelcome ? 'Курьер' : 'На линии',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      _moveMap(LatLng(_myLat, _myLon), zoom: 15);
                    },
                    icon: const Icon(Icons.my_location_rounded, size: 18, color: Colors.black),
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
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
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

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(26),
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
          Icon(icon, size: 18, color: const Color(0xFFFF8A00)),
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
