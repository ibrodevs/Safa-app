import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_maps_mapkit_lite/yandex_map.dart';
import 'package:yandex_maps_mapkit_lite/mapkit.dart' as ykit;
import 'package:yandex_maps_mapkit_lite/mapkit_factory.dart';

class OrderMapScreen extends StatefulWidget {
  const OrderMapScreen({super.key});

  @override
  State<OrderMapScreen> createState() => _OrderMapScreenState();
}

class _OrderMapScreenState extends State<OrderMapScreen> {
  static const _accent = Color(0xFFFF8A00);
  static const double _dotSize = 16;

  final ykit.Point _bishkekCenter = const ykit.Point(
    latitude: 42.8746,
    longitude: 74.6122,
  );

  ykit.MapWindow? _mapWindow;
  late final ykit.MapCameraListener _cameraListener;

  ykit.Point _userPoint = const ykit.Point(
    latitude: 42.8746,
    longitude: 74.6122,
  );

  double? _pinX;
  double? _pinY;

  @override
  void initState() {
    super.initState();
    mapkit.onStart();
    _cameraListener = _CameraListenerImpl(_onCameraPositionChanged);
  }

  @override
  void dispose() {
    final map = _mapWindow?.map;
    if (map != null) {
      map.removeCameraListener(_cameraListener);
    }
    mapkit.onStop();
    super.dispose();
  }

  void _onMapCreated(ykit.MapWindow mapWindow) {
    _mapWindow = mapWindow;
    mapWindow.map.addCameraListener(_cameraListener);

    mapWindow.map.move(
      ykit.CameraPosition(
        _bishkekCenter,
        zoom: 14.0,
        azimuth: 0.0,
        tilt: 0.0,
      ),
    );

    _updatePinScreenPosition();
    _initLocation();
  }

  void _onCameraPositionChanged(
      ykit.Map map,
      ykit.CameraPosition cameraPosition,
      ykit.CameraUpdateReason cameraUpdateReason,
      bool finished,
      ) {
    _updatePinScreenPosition();
  }

  void _updatePinScreenPosition() {
    final window = _mapWindow;
    if (window == null || !mounted) return;

    final sp = window.worldToScreen(_userPoint);
    if (sp == null) return;

    final dpr = MediaQuery.of(context).devicePixelRatio;

    setState(() {
      _pinX = sp.x / dpr;
      _pinY = (sp.y + _dotSize / 2) / dpr;
    });
  }

  Future<void> _initLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }

      if (perm != LocationPermission.always &&
          perm != LocationPermission.whileInUse) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition();

      final point = ykit.Point(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );

      if (!mounted) return;

      _userPoint = point;

      final map = _mapWindow?.map;
      if (map != null) {
        map.move(
          ykit.CameraPosition(
            _userPoint,
            zoom: 16.0,
            azimuth: 0.0,
            tilt: 0.0,
          ),
        );
      }

      _updatePinScreenPosition();
    } catch (_) {}
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
          if (_pinX != null && _pinY != null)
            Positioned(
              left: _pinX,
              top: _pinY,
              child: const _UserMarker(),
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
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
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

class _UserMarker extends StatelessWidget {
  const _UserMarker();

  @override
  Widget build(BuildContext context) {
    return FractionalTranslation(
      translation: const Offset(-0.5, -1.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _HereBubble(),
          SizedBox(height: 8),
          _MeDot(),
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
        width: 188,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _tileBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Вы здесь',
              style: TextStyle(
                fontSize: 16,
                height: 1.1,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Алкан базары',
              style: TextStyle(
                fontSize: 14,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Контейнер 74, 8 проход',
              style: TextStyle(
                fontSize: 13,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: _greyText,
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: _greyText,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
              child: const Text('Изменить'),
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

final class _CameraListenerImpl extends ykit.MapCameraListener {
  _CameraListenerImpl(this.onChanged);

  final void Function(
      ykit.Map map,
      ykit.CameraPosition cameraPosition,
      ykit.CameraUpdateReason cameraUpdateReason,
      bool finished,
      ) onChanged;

  @override
  void onCameraPositionChanged(
      ykit.Map map,
      ykit.CameraPosition cameraPosition,
      ykit.CameraUpdateReason cameraUpdateReason,
      bool finished,
      ) {
    onChanged(map, cameraPosition, cameraUpdateReason, finished);
  }
}
