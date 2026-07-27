import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../data/model/delivery_point_model.dart';
import '../../data/model/delivery_refs_models.dart';
import '../../data/repo/delivery_refs_repository.dart';
import '../../provider/delivery_address_provider.dart';
import '../../provider/delivery_autocomplete_provider.dart';

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
  static const _containerColor = Color(0xFF1E8E3E);

  final MapController _mapController = MapController();
  final TextEditingController _q = TextEditingController();
  final FocusNode _focus = FocusNode();
  final DeliveryRefsRepository _refsRepository = DeliveryRefsRepository();

  LatLng _center = const LatLng(42.8746, 74.6122);
  Timer? _reverseDebounce;
  Timer? _containersDebounce;

  List<ContainerRef> _visibleContainers = const [];
  ContainerRef? _selectedContainer;
  bool _containersLoading = false;
  int _containersRequestSerial = 0;

  @override
  void initState() {
    super.initState();

    final addressProvider = context.read<DeliveryAddressProvider>();
    final lat = addressProvider.fromLat;
    final lon = addressProvider.fromLon;

    _center = lat != null && lon != null ? LatLng(lat, lon) : widget.initial;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      context.read<DeliveryAutocompleteProvider>().clearSuggestions();
      _mapController.move(_center, 15);

      await context.read<DeliveryAddressProvider>().fetchPickerHereAddress(
        lat: _center.latitude,
        lon: _center.longitude,
      );

      _scheduleContainersRefresh(immediate: true);
    });
  }

  @override
  void dispose() {
    _reverseDebounce?.cancel();
    _containersDebounce?.cancel();
    _q.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scheduleReverse(LatLng center) {
    _reverseDebounce?.cancel();
    _reverseDebounce = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;

      context.read<DeliveryAddressProvider>().fetchPickerHereAddress(
        lat: center.latitude,
        lon: center.longitude,
      );
    });
  }

  void _scheduleContainersRefresh({bool immediate = false}) {
    _containersDebounce?.cancel();
    _containersDebounce = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 350),
      _refreshVisibleContainers,
    );
  }

  Future<void> _refreshVisibleContainers() async {
    if (!mounted) return;

    late final LatLngBounds bounds;
    try {
      bounds = _mapController.camera.visibleBounds;
    } catch (_) {
      return;
    }

    final serial = ++_containersRequestSerial;
    final latPadding =
        (bounds.north - bounds.south).abs().clamp(0.002, 0.03).toDouble() *
        0.25;
    final lonPadding =
        (bounds.east - bounds.west).abs().clamp(0.002, 0.03).toDouble() *
        0.25;

    setState(() => _containersLoading = true);

    try {
      final containers = await _refsRepository.loadContainersInBounds(
        minLat: bounds.south - latPadding,
        maxLat: bounds.north + latPadding,
        minLon: bounds.west - lonPadding,
        maxLon: bounds.east + lonPadding,
      );

      if (!mounted || serial != _containersRequestSerial) return;

      final selected = _selectedContainer;
      final merged = List<ContainerRef>.from(containers);

      if (selected != null && !merged.any((item) => item.id == selected.id)) {
        merged.add(selected);
      }

      setState(() => _visibleContainers = merged);
    } catch (_) {
      // Keep the last successfully loaded markers on transient network errors.
    } finally {
      if (mounted && serial == _containersRequestSerial) {
        setState(() => _containersLoading = false);
      }
    }
  }

  void _moveTo(LatLng point, {double zoom = 16}) {
    setState(() {
      _center = point;
      _selectedContainer = null;
    });

    _mapController.move(point, zoom);
    _scheduleReverse(point);
    _scheduleContainersRefresh();
  }

  void _selectContainer(ContainerRef container) {
    final lat = container.latValue;
    final lon = container.lonValue;
    if (lat == null || lon == null) return;

    final point = LatLng(lat, lon);

    FocusScope.of(context).unfocus();
    context.read<DeliveryAutocompleteProvider>().clearSuggestions();

    setState(() {
      _selectedContainer = container;
      _center = point;
    });

    _mapController.move(point, 17);
    _scheduleReverse(point);
    _scheduleContainersRefresh();
  }

  String _containerSubtitle(ContainerRef container) {
    final parts = <String>[
      if (container.number.trim().isNotEmpty)
        'Контейнер ${container.number.trim()}',
      if (container.passageNumber.trim().isNotEmpty)
        'Проход ${container.passageNumber.trim()}',
    ];

    return parts.join(' • ');
  }

  String _containerDetails(ContainerRef container) {
    final parts = <String>[
      if (container.bazarName.trim().isNotEmpty) container.bazarName.trim(),
      if (container.passageNumber.trim().isNotEmpty)
        'проход ${container.passageNumber.trim()}',
    ];

    return parts.join(' • ');
  }

  DeliveryPoint _buildPickedPoint({
    required String hereAddress,
  }) {
    final container = _selectedContainer;

    if (container != null &&
        container.latValue != null &&
        container.lonValue != null) {
      final title = container.bazarName.trim().isNotEmpty
          ? container.bazarName.trim()
          : (container.displayTitle.trim().isNotEmpty
                ? container.displayTitle.trim()
                : 'Контейнер ${container.number}');

      return DeliveryPoint(
        title: title,
        subtitle: _containerSubtitle(container),
        lat: container.latValue,
        lon: container.lonValue,
        bazar: container.bazarName,
        container: container.number,
        passage: container.passageNumber,
        q: '',
      );
    }

    return DeliveryPoint(
      title: hereAddress.isNotEmpty ? hereAddress : 'Точка на карте',
      subtitle: hereAddress,
      lat: _center.latitude,
      lon: _center.longitude,
      bazar: '',
      container: '',
      passage: '',
      q: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final autocomplete = context.watch<DeliveryAutocompleteProvider>();
    final address = context.watch<DeliveryAddressProvider>();

    final hereAddress = address.pickerHereAddress ?? '';
    final hereLoading = address.pickerLoading;
    final hereError = address.pickerError;
    final selectedContainer = _selectedContainer;

    final markers = _visibleContainers
        .where((container) {
          return container.latValue != null && container.lonValue != null;
        })
        .map(
          (container) => Marker(
            point: LatLng(container.latValue!, container.lonValue!),
            width: 72,
            height: 48,
            alignment: Alignment.center,
            child: _ContainerMarker(
              container: container,
              selected: selectedContainer?.id == container.id,
              onTap: () => _selectContainer(container),
            ),
          ),
        )
        .toList();

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
              onMapReady: () {
                _scheduleContainersRefresh(immediate: true);
              },
              onPositionChanged: (position, hasGesture) {
                _center = position.center;

                if (hasGesture) {
                  if (_selectedContainer != null) {
                    setState(() => _selectedContainer = null);
                  }
                  _scheduleReverse(position.center);
                }

                _scheduleContainersRefresh();
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'kg.genesis.dogo',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              if (markers.isNotEmpty) MarkerLayer(markers: markers),
            ],
          ),

          const IgnorePointer(
            child: Center(
              child: Icon(
                Icons.place_rounded,
                size: 44,
                color: _accent,
              ),
            ),
          ),

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
                        onChanged: (value) {
                          context
                              .read<DeliveryAutocompleteProvider>()
                              .onQueryChanged(value);
                          setState(() {});
                        },
                      ),
                    ),
                    if (_q.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _q.clear();
                          context
                              .read<DeliveryAutocompleteProvider>()
                              .clearSuggestions();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 76,
            right: 16,
            child: _ContainersStatus(
              loading: _containersLoading,
              count: _visibleContainers.length,
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
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = autocomplete.items[index];

                            return ListTile(
                              title: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                item.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                context
                                    .read<DeliveryAutocompleteProvider>()
                                    .clearSuggestions();
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
                    Text(
                      selectedContainer == null
                          ? 'Точка на карте'
                          : 'Выбран контейнер',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedContainer != null
                          ? _containerSubtitle(selectedContainer)
                          : hereLoading
                          ? 'Определяем адрес...'
                          : (hereError != null && hereError.isNotEmpty)
                          ? 'Адрес недоступен'
                          : (hereAddress.isEmpty
                                ? 'Адрес не найден'
                                : hereAddress),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (selectedContainer != null &&
                        _containerDetails(selectedContainer).isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _containerDetails(selectedContainer),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF7A828D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(
                            _buildPickedPoint(hereAddress: hereAddress),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        child: Text(
                          selectedContainer == null
                              ? 'Выбрать точку'
                              : 'Выбрать контейнер',
                        ),
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

class _ContainersStatus extends StatelessWidget {
  const _ContainersStatus({
    required this.loading,
    required this.count,
  });

  final bool loading;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: const Color(0x22000000),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5EAF0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _MapPickerScreenState._containerColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            const SizedBox(width: 7),
            Text(
              loading ? 'Контейнеры...' : 'Контейнеры: $count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2933),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContainerMarker extends StatelessWidget {
  const _ContainerMarker({
    required this.container,
    required this.selected,
    required this.onTap,
  });

  final ContainerRef container;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Контейнер ${container.number}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            constraints: const BoxConstraints(
              minWidth: 38,
              maxWidth: 70,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 9 : 7,
              vertical: selected ? 7 : 6,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? _MapPickerScreenState._accent
                  : _MapPickerScreenState._containerColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white,
                width: selected ? 2.5 : 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              container.number,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
