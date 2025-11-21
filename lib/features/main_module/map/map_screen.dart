// lib/features/main_module/map/order_map_screen.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

class OrderMapScreen extends StatefulWidget {
  const OrderMapScreen({super.key});
  @override
  State<OrderMapScreen> createState() => _OrderMapScreenState();
}

class _OrderMapScreenState extends State<OrderMapScreen> {
  static const _accent = Color(0xFFFF8A00);
  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _chev = Color(0xFFC7CFD9);

  final MapObjectId _meId = const MapObjectId('me');
  YandexMapController? _controller;

  Point _center = const Point(latitude: 42.8746, longitude: 74.6122);
  List<MapObject> _objects = const [];

  double? _bubbleLeft;
  double? _bubbleTop;
  final Size _bubbleSize = const Size(252, 112);

  @override
  void initState() {
    super.initState();

    if (defaultTargetPlatform == TargetPlatform.android) {
      AndroidYandexMap.useAndroidViewSurface = false;
    }

    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        p = await Geolocator.requestPermission();
      }

      Position? pos;
      if (p == LocationPermission.always || p == LocationPermission.whileInUse) {
        pos = await Geolocator.getCurrentPosition().catchError((_) => null);
      }

      if (pos != null) {
        _center = Point(latitude: pos.latitude, longitude: pos.longitude);
      }

      await _buildObjects();

      if (!mounted || _controller == null) return;

      await _controller!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _center, zoom: 16.5),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 0.3,
        ),
      );

      _updateBubblePosition();
    } catch (_) {
      await _buildObjects();
    }
  }

  Future<void> _buildObjects() async {
    final dotBytes = await _circleBytes(
      10,
      _accent,
      stroke: Colors.white,
      strokeWidth: 3,
    );

    final me = PlacemarkMapObject(
      mapId: _meId,
      point: _center,
      icon: PlacemarkIcon.single(
        PlacemarkIconStyle(
          image: BitmapDescriptor.fromBytes(dotBytes),
        ),
      ),
      opacity: 1,
      zIndex: 2,
    );

    if (mounted) {
      setState(() => _objects = [me]);
    }
  }

  Future<Uint8List> _circleBytes(
      double radius,
      Color color, {
        Color? stroke,
        double strokeWidth = 0,
      }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = (radius + strokeWidth) * 2;
    final center = Offset(size / 2, size / 2);

    if (strokeWidth > 0 && stroke != null) {
      final sp = Paint()
        ..color = stroke
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius + strokeWidth, sp);
    }

    final p = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, p);

    final pic = recorder.endRecording();
    final img = await pic.toImage(size.ceil(), size.ceil());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _updateBubblePosition() async {
    if (!mounted || _controller == null) return;

    final sp = await _controller!.getScreenPoint(_center);
    if (sp == null) return;

    final left = sp.x - (_bubbleSize.width / 2);
    final top = sp.y - _bubbleSize.height - 8;

    if (mounted) {
      setState(() {
        _bubbleLeft = left;
        _bubbleTop = top;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInsets = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          YandexMap(
            rotateGesturesEnabled: false,
            mapObjects: _objects,
            onMapCreated: (c) async {
              _controller = c;
              await _controller!.moveCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: _center, zoom: 16.5),
                ),
              );

              _updateBubblePosition();
            },
            onCameraPositionChanged: (position, _, __) {
              _updateBubblePosition();
            },
          ),

          if (_bubbleLeft != null && _bubbleTop != null)
            Positioned(
              left: _bubbleLeft,
              top: _bubbleTop,
              width: _bubbleSize.width,
              height: _bubbleSize.height,
              child: _HereBubble(
                onEdit: () {
                  // TODO: открыть поиск адреса, если нужно
                },
              ),
            ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + bottomInsets,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _InputTile(
                  iconAsset: 'assets/icons/ic_box.svg',
                  title: 'Контейнер 74, 8 проход',
                  enabled: true,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      child: _InputTile(
                        iconAsset: 'assets/icons/ic_box.svg',
                        title: 'Куда доставить',
                        enabled: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _AddAddressButton(
                      onTap: () {
                        // TODO: добавить адрес
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('Далее'),
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


class _HereBubble extends StatelessWidget {
  const _HereBubble({this.onEdit});
  final VoidCallback? onEdit;

  static const _tileBorder = Color(0xFFE9EDF2);
  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: const Color(0x22000000),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _tileBorder, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Вы здесь',
              style: TextStyle(
                fontSize: 18,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Алкан базары',
              style: TextStyle(
                fontSize: 16,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Контейнер 74, 8 проход',
              style: TextStyle(
                fontSize: 14,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: _greyText,
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: _greyText,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: const Size(0, 0),
                  textStyle: const TextStyle(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Изменить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputTile extends StatelessWidget {
  const _InputTile({
    required this.iconAsset,
    required this.title,
    this.enabled = true,
  });

  final String iconAsset;
  final String title;
  final bool enabled;

  static const _accent = Color(0xFFFF8A00);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _chev = Color(0xFFC7CFD9);
  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 16,
      height: 1.2,
      fontWeight: FontWeight.w800,
      color: enabled ? Colors.black : _greyText,
    );

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _tileBorder, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          SvgPicture.asset(
            iconAsset,
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              _accent,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: _chev,
          ),
        ],
      ),
    );
  }
}

class _AddAddressButton extends StatelessWidget {
  const _AddAddressButton({this.onTap});
  final VoidCallback? onTap;

  static const _accent = Color(0xFFFF8A00);
  static const _tileBorder = Color(0xFFE9EDF2);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _tileBorder, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: _accent,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: const Text(
          '+ Адрес',
          style: TextStyle(color: Colors.black),
        ),
      ),
    );
  }
}
