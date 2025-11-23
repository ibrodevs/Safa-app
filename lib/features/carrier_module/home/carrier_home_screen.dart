import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:yandex_maps_mapkit_lite/yandex_map.dart';
import 'package:yandex_maps_mapkit_lite/mapkit.dart' as ykit;
import 'package:yandex_maps_mapkit_lite/mapkit_factory.dart';

class CarrierHomeScreen extends StatefulWidget {
  const CarrierHomeScreen({super.key});

  @override
  State<CarrierHomeScreen> createState() => _CarrierHomeScreenState();
}

class _CarrierHomeScreenState extends State<CarrierHomeScreen> {
  static const _accent = Color(0xFFFF8A00);

  final ykit.Point _bishkekCenter = const ykit.Point(
    latitude: 42.8746,
    longitude: 74.6122,
  );

  ykit.MapWindow? _mapWindow;

  @override
  void initState() {
    super.initState();
    mapkit.onStart();
  }

  @override
  void dispose() {
    mapkit.onStop();
    super.dispose();
  }

  void _onMapCreated(ykit.MapWindow mapWindow) {
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
  }

  @override
  Widget build(BuildContext context) {
    final bottomInsets = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          YandexMap(
            onMapCreated: _onMapCreated,
          ),
        ],
      ),
    );
  }
}

