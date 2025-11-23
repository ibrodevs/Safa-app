import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
