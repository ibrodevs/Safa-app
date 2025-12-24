import 'dart:async';

import 'package:dogo/features/main_module/map/provider/delivery_address_provider.dart';
import 'package:dogo/features/main_module/map/view/components/deliveri_point_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../type_cargo/view/cargo_type_screen.dart' show CargoTypeResult, CargoRouteArgs;
import '../../../../data/network/api_service.dart';
import '../../type_cargo/view/cargo_type_screen.dart';
import '../data/model/delivery_point_model.dart';
import 'components/intermediate_point_sheet.dart';

class OrderMapScreen extends StatefulWidget {
  const OrderMapScreen({super.key});

  @override
  State<OrderMapScreen> createState() => _OrderMapScreenState();
}

class _OrderMapScreenState extends State<OrderMapScreen> {
  static const _accent = Color(0xFFFF8A00);
  final LatLng _bishkekCenter = const LatLng(42.8746, 74.6122);
  double _myLat = 42.8746;
  double _myLon = 74.6122;

  double _centerLat = 42.8746;
  double _centerLon = 74.6122;

  final MapController _mapController = MapController();

  Timer? _reverseDebounce;

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

  @override
  void dispose() {
    _reverseDebounce?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location service disabled');
        await context.read<DeliveryAddressProvider>().fetchHereAddress(
          lat: _bishkekCenter.latitude,
          lon: _bishkekCenter.longitude,
        );
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        debugPrint('Location permission deniedForever');
        await context.read<DeliveryAddressProvider>().fetchHereAddress(
          lat: _bishkekCenter.latitude,
          lon: _bishkekCenter.longitude,
        );
        return;
      }
      if (perm != LocationPermission.always && perm != LocationPermission.whileInUse) {
        debugPrint('Location permission not granted: $perm');
        await context.read<DeliveryAddressProvider>().fetchHereAddress(
          lat: _bishkekCenter.latitude,
          lon: _bishkekCenter.longitude,
        );
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
      _mapController.move(LatLng(_myLat, _myLon), 15);

      await context.read<DeliveryAddressProvider>().fetchHereAddress(
        lat: _centerLat,
        lon: _centerLon,
      );

      debugPrint('Location OK: $_myLat, $_myLon');
    } catch (e, st) {
      debugPrint('initLocation error: $e\n$st');
      if (mounted) {
        await context.read<DeliveryAddressProvider>().fetchHereAddress(
          lat: _bishkekCenter.latitude,
          lon: _bishkekCenter.longitude,
        );
      }
    }
  }


  void _scheduleReverseByCenter(LatLng center) {
    _reverseDebounce?.cancel();
    _reverseDebounce = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      context.read<DeliveryAddressProvider>().fetchHereAddress(
        lat: center.latitude,
        lon: center.longitude,
      );
    });
  }

  Future<void> _openIntermediatePointSheet() async {
    final result = await showModalBottomSheet<DeliveryPoint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

    final result = await showModalBottomSheet<DeliveryPoint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeliveryPointSheet(
        mainTitle: mainTitle,
        bazarTitle: bazarTitle,
      ),
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
    final hereAddress = addressProvider.hereAddress;
    final originTitle = (hereAddress != null && hereAddress.isNotEmpty) ? hereAddress : 'Мой адрес';

    stops.add({
      'title': originTitle,
      'lat': _myLat, // старт именно от моих координат
      'lon': _myLon,
    });

    for (final p in _intermediatePoints) {
      stops.add({
        'title': p.title,
        'lat': p.lat,
        'lon': p.lon,
      });
    }

    final dest = _deliveryPoint!;
    stops.add({
      'title': dest.title,
      'lat': dest.lat,
      'lon': dest.lon,
    });

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
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

    final startTitle = (detailText != null && detailText.isNotEmpty) ? detailText : fromTitle;
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
    final hereAddress = addressProvider.hereAddress;
    final hereLoading = addressProvider.loading;

    String fromTitle;
    String? bazarTitle;
    String? detailText;

    if (hereLoading) {
      fromTitle = 'Определяем адрес...';
    } else if (hereAddress == null || hereAddress.isEmpty) {
      fromTitle = 'Определяем адрес...';
    } else {
      final parsed = _parseAddressForUi(hereAddress);
      fromTitle = parsed.fullAfterCity.isNotEmpty ? parsed.fullAfterCity : hereAddress;
      bazarTitle = parsed.marketTitle;
      detailText = parsed.detail;
    }

    final myPoint = LatLng(_myLat, _myLon);
    final hereError = addressProvider.error;
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

                if (hasGesture) {
                  _scheduleReverseByCenter(c);
                }
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
                          _HereBubble(
                            address: hereAddress,
                            loading: hereLoading,
                            error: hereError,
                            marketTitle: bazarTitle,
                            detail: detailText,
                          ),
                          const SizedBox(height: 8),
                          const _MeDot(),
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
                ? _SearchingSheet(
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
                        title: _deliveryPoint?.title ?? 'Куда доставить',
                        enabled: _deliveryPoint != null,
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
                    onPressed: (_deliveryPoint == null || _creatingShipment)
                        ? null
                        : () async {
                      final stops = _buildStopsForSearchSheet(
                        fromTitle: fromTitle,
                        bazarTitle: bazarTitle,
                        detailText: detailText,
                      );
                      final result = await context.push<CargoTypeResult>(
                        '/type_cargo',
                        extra: CargoRouteArgs(stops: stops),
                      );

                      if (result != null && mounted) {
                        await _createShipmentWithCargo(result);
                      }
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
                    child: Text(_creatingShipment ? 'Создаём заказ…' : 'Далее'),
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
    this.error,
  });

  final VoidCallback? onEdit;
  final String? address;
  final bool loading;
  final String? marketTitle;
  final String? detail;
  final String? error;
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    String titleLine;
    String subtitleLine;

    if (loading) {
      titleLine = marketTitle ?? 'Определяем адрес...';
      subtitleLine = 'Определяем адрес...';
    } else if (address == null || address!.isEmpty) {
      titleLine = marketTitle ?? 'Определяем адрес...';
      subtitleLine = 'Определяем адрес...';
    } else {
      if (marketTitle != null || detail != null) {
        titleLine = marketTitle ?? 'Определяем адрес...';
        subtitleLine = detail ?? address!;
      } else {
        final parsed = _parseAddressForUi(address);
        titleLine = parsed.marketTitle ?? 'Определяем адрес...';
        subtitleLine = parsed.detail ?? parsed.fullAfterCity;
      }
    }
    if (error != null && error!.isNotEmpty) {
      titleLine = 'Не удалось получить адрес';
      subtitleLine = 'Проверь интернет / доступ к геокодингу';
    } else if (loading) {

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
                colorFilter: const ColorFilter.mode(_accent, BlendMode.srcIn),
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

class _SearchingSheet extends StatelessWidget {
  const _SearchingSheet({
    required this.stops,
    required this.cancelling,
    required this.onCancel,
  });

  final List<DeliveryPoint> stops;
  final bool cancelling;
  final VoidCallback onCancel;

  static const _green = Color(0xFF22C55E);
  static const _greyText = Color(0xFF9FA4AD);
  static const _accentBorder = Color(0xFFFF8A00);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Поиск тачкистов',
              style: TextStyle(
                fontSize: 24,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: _green,
              ),
            ),
            const SizedBox(height: 24),
            for (int i = 0; i < stops.length; i++) ...[
              Text(
                stops[i].title,
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stops[i].subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: _greyText,
                ),
              ),
              if (i != stops.length - 1) ...[
                const SizedBox(height: 16),
                const Icon(
                  Icons.arrow_downward_rounded,
                  size: 26,
                  color: Colors.black,
                ),
                const SizedBox(height: 16),
              ] else ...[
                const SizedBox(height: 24),
              ],
            ],
            const Divider(
              height: 1,
              color: Color(0xFFE0E4EA),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: cancelling ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: _accentBorder,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  cancelling ? 'Отменяем…' : 'Отменить поиск',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ParsedAddress {
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
    var name = raw.startsWith(prefix) ? raw.substring(prefix.length).trim() : raw;
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
