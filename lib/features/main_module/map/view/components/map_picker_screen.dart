import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../provider/delivery_autocomplete_provider.dart';
import '../../provider/delivery_address_provider.dart';
import '../../data/model/delivery_point_model.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({
    super.key,
    required this.initial,
    this.title = 'Выбор точки',
  });

  final LatLng initial;
  final String title;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const _accent = Color(0xFFFF8A00);

  final MapController _mapController = MapController();
  final TextEditingController _q = TextEditingController();
  final FocusNode _focus = FocusNode();

  LatLng _center = const LatLng(42.8746, 74.6122);
  Timer? _reverseDebounce;

  @override
  void initState() {
    super.initState();

    final p = context.read<DeliveryAddressProvider>();

    final lat = p.fromLat;
    final lon = p.fromLon;

    if (lat != null && lon != null) {
      _center = LatLng(lat, lon);
    } else {
      _center = widget.initial;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      context.read<DeliveryAutocompleteProvider>().clearSuggestions();
      _mapController.move(_center, 15);
      await context.read<DeliveryAddressProvider>().fetchPickerHereAddress(
        lat: _center.latitude,
        lon: _center.longitude,
      );
    });
  }


  @override
  void dispose() {
    _reverseDebounce?.cancel();
    _q.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scheduleReverse(LatLng c) {
    _reverseDebounce?.cancel();
    _reverseDebounce = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      context.read<DeliveryAddressProvider>().fetchPickerHereAddress(
        lat: c.latitude,
        lon: c.longitude,
      );
    });
  }

  void _moveTo(LatLng p, {double zoom = 16}) {
    _mapController.move(p, zoom);
    setState(() => _center = p);
    _scheduleReverse(p);
  }

  @override
  Widget build(BuildContext context) {
    final autocomplete = context.watch<DeliveryAutocompleteProvider>();
    final address = context.watch<DeliveryAddressProvider>();


    final hereAddress = address.pickerHereAddress ?? '';
    final hereLoading = address.pickerLoading;
    final hereError = address.pickerError;


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onPositionChanged: (pos, hasGesture) {
                _center = pos.center;
                if (hasGesture) _scheduleReverse(pos.center);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'kg.genesis.dogo',
              ),
            ],
          ),

          // Центральный пин выбора
          const IgnorePointer(
            child: Center(
              child: Icon(
                Icons.place_rounded,
                size: 44,
                color: _accent,
              ),
            ),
          ),

          // Поиск сверху
          Positioned(
            left: 16,
            right: 16,
            top: 12,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 10,
              shadowColor: const Color(0x22000000),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: _accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _q,
                        focusNode: _focus,
                        cursorColor: Colors.black,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Поиск адреса',
                        ),
                        onChanged: context.read<DeliveryAutocompleteProvider>().onQueryChanged,
                      ),
                    ),
                    if (_q.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _q.clear();
                          context.read<DeliveryAutocompleteProvider>().clearSuggestions();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
              ),
            ),
          ),

          if (autocomplete.loading || autocomplete.items.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              top: 72,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 10,
                shadowColor: const Color(0x22000000),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (autocomplete.loading)
                        const LinearProgressIndicator(minHeight: 2),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: autocomplete.items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final item = autocomplete.items[i];
                            return ListTile(
                              title: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                item.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                context.read<DeliveryAutocompleteProvider>().clearSuggestions();
                                _moveTo(LatLng(item.lat, item.lon));
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Нижняя карточка с адресом и кнопкой “Выбрать”
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.viewPaddingOf(context).bottom,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              elevation: 12,
              shadowColor: const Color(0x22000000),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Точка на карте',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hereLoading
                          ? 'Определяем адрес...'
                          : (hereError != null && hereError.isNotEmpty)
                          ? 'Адрес недоступен'
                          : (hereAddress.isEmpty ? 'Адрес не найден' : hereAddress),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final p = DeliveryPoint(
                            title: hereAddress.isNotEmpty ? hereAddress : 'Точка на карте',
                            subtitle: hereAddress,
                            lat: _center.latitude,
                            lon: _center.longitude,
                            bazar: '',
                            container: '',
                            passage: '',
                            q: '',
                          );
                          Navigator.of(context).pop(p);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        child: const Text('Выбрать'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
