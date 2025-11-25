import 'package:dogo/features/main_module/map/provider/delivery_address_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
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

      await context.read<DeliveryAddressProvider>().fetchHereAddress(
        lat: _userPoint.latitude,
        lon: _userPoint.longitude,
      );

      _updatePinScreenPosition();
    } catch (_) {}
  }
  void _openIntermediatePointSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottom = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: const _IntermediatePointSheet(
            addressLine: 'Контейнер 74, 8 проход',
            placeLine: 'Алкан базары',
          ),
        );
      },
    );
  }

  void _openDeliveryPointSheet() {
    final addressProvider = context.read<DeliveryAddressProvider>();
    final hereAddress = addressProvider.hereAddress;
    final hereLoading = addressProvider.loading;

    String mainTitle = 'Контейнер 74, 8 проход';
    String? bazarTitle = 'Алкан базары';

    if (!hereLoading && hereAddress != null && hereAddress.isNotEmpty) {
      final parsed = _parseAddressForUi(hereAddress);
      if (parsed.detail != null && parsed.detail!.isNotEmpty) {
        mainTitle = parsed.detail!;
      } else if (parsed.fullAfterCity.isNotEmpty) {
        mainTitle = parsed.fullAfterCity;
      }
      if (parsed.marketTitle != null && parsed.marketTitle!.isNotEmpty) {
        bazarTitle = parsed.marketTitle;
      }
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeliveryPointSheet(
        mainTitle: mainTitle,
        bazarTitle: bazarTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInsets = MediaQuery.viewPaddingOf(context).bottom;

    final addressProvider = context.watch<DeliveryAddressProvider>();
    final hereAddress = addressProvider.hereAddress;
    final hereLoading = addressProvider.loading;

    String fromTitle;
    String? bazarTitle;
    String? detailText;

    if (hereLoading) {
      fromTitle = 'Определяем адрес...';
    } else if (hereAddress == null || hereAddress.isEmpty) {
      fromTitle = 'Не удалось определить';
    } else {
      final parsed = _parseAddressForUi(hereAddress);
      fromTitle =
      parsed.fullAfterCity.isNotEmpty ? parsed.fullAfterCity : hereAddress;
      bazarTitle = parsed.marketTitle;
      detailText = parsed.detail;
    }

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
              child: _UserMarker(
                address: hereAddress,
                loading: hereLoading,
                marketTitle: bazarTitle,
                detail: detailText,
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + bottomInsets,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _InputTile(
                  iconAsset: 'assets/icons/ic_box.svg',
                  title: fromTitle,
                  enabled: true,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _InputTile(
                        iconAsset: 'assets/icons/ic_box.svg',
                        title: 'Куда доставить',
                        enabled: false,
                        onTap: _openDeliveryPointSheet,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _AddAddressButton(
                      onTap: _openIntermediatePointSheet,
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
  const _UserMarker({
    required this.address,
    required this.loading,
    this.marketTitle,
    this.detail,
  });

  final String? address;
  final bool loading;
  final String? marketTitle;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return FractionalTranslation(
      translation: const Offset(-0.5, -1.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HereBubble(
            address: address,
            loading: loading,
            marketTitle: marketTitle,
            detail: detail,
          ),
          const SizedBox(height: 8),
          const _MeDot(),
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
  const _HereBubble({
    this.onEdit,
    this.address,
    this.loading = false,
    this.marketTitle,
    this.detail,
  });

  final VoidCallback? onEdit;
  final String? address;
  final bool loading;
  final String? marketTitle;
  final String? detail;

  static const _tileBorder = Color(0xFFE9EDF2);
  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    String titleLine;
    String subtitleLine;

    if (loading) {
      titleLine = marketTitle ?? 'Алкан базары';
      subtitleLine = 'Определяем адрес...';
    } else if (address == null || address!.isEmpty) {
      titleLine = marketTitle ?? 'Алкан базары';
      subtitleLine = 'Не удалось определить';
    } else {
      if (marketTitle != null || detail != null) {
        titleLine = marketTitle ?? 'Алкан базары';
        subtitleLine = detail ?? address!;
      } else {
        final parsed = _parseAddressForUi(address);
        titleLine = parsed.marketTitle ?? 'Алкан базары';
        subtitleLine = parsed.detail ?? parsed.fullAfterCity;
      }
    }

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
            Text(
              titleLine,
              style: const TextStyle(
                fontSize: 14,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitleLine,
              style: const TextStyle(
                fontSize: 13,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: _greyText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
    this.onTap,
  });

  final String iconAsset;
  final String title;
  final bool enabled;
  final VoidCallback? onTap;

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
    final radius = BorderRadius.circular(12);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _tileBorder, width: 1),
            borderRadius: radius,
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
        ),
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
          backgroundColor: Colors.white,
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

class _DeliveryPointSheet extends StatelessWidget {
  const _DeliveryPointSheet({
    required this.mainTitle,
    this.bazarTitle,
  });

  final String mainTitle;
  final String? bazarTitle;

  static const _accent = Color(0xFFFF8A00);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: const Color(0x33000000),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Точка доставки',
                    style: TextStyle(
                      fontSize: 28,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mainTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bazarTitle ?? 'Алкан базары',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: _greyText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F7FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _tileBorder),
                          ),
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/ic_box.svg',
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(
                                  _accent,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: TextField(
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    hintText: 'Откуда отправка',
                                    hintStyle: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: _greyText,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 10,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: _accent,
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        icon: const Icon(
                          Icons.near_me_rounded,
                          size: 20,
                        ),
                        label: const Text('Карта'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: _tileBorder),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Expanded(
                        child: _DeliveryTypeChip(title: 'Контейнер'),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _DeliveryTypeChip(title: 'Проход'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
          ),
        ),
      ),
    );
  }
}

class _DeliveryTypeChip extends StatelessWidget {
  const _DeliveryTypeChip({required this.title});

  final String title;

  static const _accent = Color(0xFFFF8A00);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _tileBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/ic_box.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              _accent,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _greyText,
            ),
          ),
        ],
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

class _ParsedAddress {
  final String fullAfterCity;
  final String? marketTitle;
  final String? detail;

  const _ParsedAddress({
    required this.fullAfterCity,
    this.marketTitle,
    this.detail,
  });
}

_ParsedAddress _parseAddressForUi(String? address) {
  if (address == null) {
    return const _ParsedAddress(fullAfterCity: '');
  }

  final parts = address
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return const _ParsedAddress(fullAfterCity: '');
  }

  if (parts.length <= 2) {
    final full = parts.join(', ');
    return _ParsedAddress(
      fullAfterCity: full,
      marketTitle: parts.last,
      detail: null,
    );
  }

  final rest = parts.sublist(2);
  final fullAfterCity = rest.join(', ');

  var marketIdx = -1;
  for (var i = rest.length - 1; i >= 0; i--) {
    final lower = rest[i].toLowerCase();
    if (lower.startsWith('рынок ')) {
      marketIdx = i;
      break;
    }
  }

  String? marketTitle;
  String? detail;

  if (marketIdx != -1) {
    final raw = rest[marketIdx];
    const prefix = 'рынок ';
    var name =
    raw.startsWith(prefix) ? raw.substring(prefix.length).trim() : raw;
    if (name.isEmpty) {
      name = raw;
    }
    marketTitle = '$name базары';

    if (marketIdx + 1 < rest.length) {
      final detailParts = rest.sublist(marketIdx + 1);
      var d = detailParts.join(', ');
      if (d.isNotEmpty) {
        d = '$d контейнер';
      }
      detail = d;
    }
  } else {
    marketTitle = rest.first;
    if (rest.length > 1) {
      var d = rest.sublist(1).join(', ');
      if (d.isNotEmpty) {
        d = '$d контейнер';
      }
      detail = d;
    }
  }

  return _ParsedAddress(
    fullAfterCity: fullAfterCity,
    marketTitle: marketTitle,
    detail: detail,
  );
}
class _IntermediatePointSheet extends StatelessWidget {
  const _IntermediatePointSheet({
    required this.addressLine,
    required this.placeLine,
  });

  final String addressLine;
  final String placeLine;

  static const _accent = Color(0xFFFF8A00);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Промежуточная точка',
                  style: TextStyle(
                    fontSize: 28,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  addressLine,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  placeLine,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: _greyText,
                  ),
                ),
                const SizedBox(height: 24),
                const _PrimaryInputRow(),
                const SizedBox(height: 22),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: _tileBorder,
                ),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    Expanded(
                      child: _TagButton(
                        title: 'Контейнер',
                        iconAsset: 'assets/icons/ic_box.svg',
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _TagButton(
                        title: 'Проход',
                        iconAsset: 'assets/icons/ic_box.svg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: null, // пока просто заглушка, как в макете
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Далее'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryInputRow extends StatelessWidget {
  const _PrimaryInputRow();

  static const _accent = Color(0xFFFF8A00);
  static const _tileBorder = Color(0xFFE9EDF2);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _tileBorder, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_box.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    _accent,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Откуда отправка',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC7CFD9),
                      ),
                    ),
                    cursorColor: Colors.black,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.near_me_rounded,
                  size: 20,
                  color: _accent,
                ),
                SizedBox(width: 4),
                Text(
                  'Карта',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TagButton extends StatelessWidget {
  const _TagButton({
    required this.title,
    required this.iconAsset,
  });

  final String title;
  final String iconAsset;

  static const _accent = Color(0xFFFF8A00);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _greyText = Color(0xFFC7CFD9);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _tileBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _greyText,
            ),
          ),
        ],
      ),
    );
  }
}
