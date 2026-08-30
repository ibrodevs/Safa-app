import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/map/safa_yandex_map.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../data/model/delivery_point_model.dart';
import '../../data/model/delivery_refs_models.dart';
import '../../data/model/market_map_feature.dart';
import '../../data/repo/delivery_refs_repository.dart';
import '../../data/repo/market_map_repository.dart';
import '../../provider/delivery_address_provider.dart';
import '../../provider/delivery_autocomplete_provider.dart';
import '../widgets/container_map_marker.dart';
import '../widgets/market_map_layers.dart';

/// Экран выбора точки на карте.
///
/// Точка выбирается тапом или перемещением карты. После остановки камеры
/// выполняется reverse-геокодирование; координаты никогда не используются как
/// видимая подпись адреса.
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({
    super.key,
    required this.initial,
    this.title = 'Выбор точки',
    this.addressOnly = false,
    this.autofocusSearch = false,
  });

  final LatLng initial;
  final String title;
  final bool addressOnly;
  final bool autofocusSearch;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  /// Ниже этого масштаба подписи контейнеров скрываются.
  static const double _containerLabelMinZoom = 17;
  static const double _containerShapeMinZoom = 15;
  static const int _maxRenderedContainerShapes = 72;
  static const int _maxRenderedContainerMarkers = 96;
  static const int _maxRenderedPublishedContainers = 220;

  final SafaMapController _mapController = SafaMapController();
  final TextEditingController _query = TextEditingController();
  final FocusNode _focus = FocusNode();
  final DeliveryRefsRepository _refsRepository = DeliveryRefsRepository();
  final MarketMapRepository _marketMapRepository = MarketMapRepository();

  LatLng _center = const LatLng(42.8746, 74.6122);

  /// Точка, для которой запрошен показанный адрес. Камера после тапа ещё
  /// анимируется, поэтому подтверждать надо именно её, а не текущий центр.
  LatLng? _addressPoint;
  double _zoom = 15;
  Timer? _reverseDebounce;
  Timer? _containersDebounce;
  Timer? _marketMapDebounce;
  Timer? _mapIdleDebounce;

  List<ContainerRef> _visibleContainers = const [];
  ContainerRef? _selectedContainer;
  List<MarketMapFeature> _marketMapFeatures = const [];
  MarketMapRenderData? _marketMapRenderCache;
  int? _marketMapRenderZoomBucket;
  int? _marketMapRenderFeatureCount;
  int? _marketMapRenderFeatureHash;
  int? _marketMapRenderCenterLatBucket;
  int? _marketMapRenderCenterLonBucket;
  bool? _marketMapRenderMoving;
  LatLngBounds? _lastContainersBounds;
  int? _lastContainersZoomBucket;
  LatLngBounds? _lastMarketMapBounds;
  int? _lastMarketMapZoomBucket;
  bool _mapMoving = false;
  bool _containersLoading = false;
  bool _marketMapLoading = false;
  bool _containersRefreshPending = false;
  bool _marketMapRefreshPending = false;
  int _containersRequestSerial = 0;
  int _marketMapRequestSerial = 0;

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

      _addressPoint = _center;
      await context.read<DeliveryAddressProvider>().fetchPickerHereAddress(
        lat: _center.latitude,
        lon: _center.longitude,
        preferPublicAddress: widget.addressOnly,
      );

      _scheduleContainersRefresh(immediate: true);
      _scheduleMarketMapRefresh(immediate: true);
      if (widget.autofocusSearch && mounted) {
        _focus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _reverseDebounce?.cancel();
    _containersDebounce?.cancel();
    _marketMapDebounce?.cancel();
    _mapIdleDebounce?.cancel();
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scheduleReverse(LatLng center, {bool immediate = false}) {
    _reverseDebounce?.cancel();

    void run() {
      if (!mounted) return;

      _addressPoint = center;
      context.read<DeliveryAddressProvider>().fetchPickerHereAddress(
        lat: center.latitude,
        lon: center.longitude,
        preferPublicAddress: widget.addressOnly,
      );
    }

    if (immediate) {
      run();
      return;
    }

    _reverseDebounce = Timer(const Duration(milliseconds: 650), run);
  }

  void _scheduleContainersRefresh({bool immediate = false}) {
    if (!SafaMobileMapFeatures.backendDrawingLayersEnabled) return;
    _containersDebounce?.cancel();
    _containersDebounce = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 350),
      _refreshVisibleContainers,
    );
  }

  void _scheduleMarketMapRefresh({bool immediate = false}) {
    if (!SafaMobileMapFeatures.backendDrawingLayersEnabled) return;
    _marketMapDebounce?.cancel();
    _marketMapDebounce = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 450),
      _refreshMarketMap,
    );
  }

  void _scheduleMapIdle(LatLng center) {
    _mapIdleDebounce?.cancel();
    _mapIdleDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() => _mapMoving = false);
      if (_selectedContainer == null) _scheduleReverse(center);
      _scheduleContainersRefresh();
      _scheduleMarketMapRefresh();
    });
  }

  bool _shouldReloadBounds(LatLngBounds previous, LatLngBounds next) {
    final previousLatSpan = (previous.north - previous.south).abs();
    final previousLonSpan = (previous.east - previous.west).abs();
    final previousCenter = previous.center;
    final nextCenter = next.center;
    final latShift = (previousCenter.latitude - nextCenter.latitude).abs();
    final lonShift = (previousCenter.longitude - nextCenter.longitude).abs();

    return latShift > previousLatSpan * 0.25 ||
        lonShift > previousLonSpan * 0.25;
  }

  Future<void> _refreshVisibleContainers() async {
    if (!SafaMobileMapFeatures.backendDrawingLayersEnabled) return;
    if (!mounted) return;
    if (_containersLoading) {
      _containersRefreshPending = true;
      return;
    }

    late final LatLngBounds bounds;
    try {
      bounds = _mapController.visibleBounds!;
    } catch (_) {
      return;
    }

    final zoomBucket = _zoom.floor();
    final previousBounds = _lastContainersBounds;
    if (previousBounds != null &&
        _lastContainersZoomBucket == zoomBucket &&
        !_shouldReloadBounds(previousBounds, bounds)) {
      return;
    }

    final serial = ++_containersRequestSerial;
    final latPadding =
        (bounds.north - bounds.south).abs().clamp(0.002, 0.03).toDouble() *
        0.25;
    final lonPadding =
        (bounds.east - bounds.west).abs().clamp(0.002, 0.03).toDouble() * 0.25;

    if (_visibleContainers.isEmpty) {
      setState(() => _containersLoading = true);
    } else {
      _containersLoading = true;
    }

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

      setState(() {
        _visibleContainers = merged;
        _containersLoading = false;
        _lastContainersBounds = bounds;
        _lastContainersZoomBucket = zoomBucket;
      });
      _runPendingContainersRefresh();
    } catch (_) {
      // Keep the last successfully loaded markers on transient network errors.
      if (!mounted || serial != _containersRequestSerial) return;
      if (_visibleContainers.isEmpty) {
        setState(() => _containersLoading = false);
      } else {
        _containersLoading = false;
      }
      _runPendingContainersRefresh();
    }
  }

  void _runPendingContainersRefresh() {
    if (!_containersRefreshPending || !mounted) return;
    _containersRefreshPending = false;
    _scheduleContainersRefresh(immediate: true);
  }

  Future<void> _refreshMarketMap() async {
    if (!SafaMobileMapFeatures.backendDrawingLayersEnabled) return;
    if (!mounted) return;
    if (_marketMapLoading) {
      _marketMapRefreshPending = true;
      return;
    }

    late final LatLngBounds bounds;
    try {
      bounds = _mapController.visibleBounds!;
    } catch (_) {
      return;
    }

    final zoomBucket = _zoom.floor();
    final previousBounds = _lastMarketMapBounds;
    if (previousBounds != null &&
        _lastMarketMapZoomBucket == zoomBucket &&
        !_shouldReloadBounds(previousBounds, bounds)) {
      return;
    }

    final serial = ++_marketMapRequestSerial;
    _marketMapLoading = true;
    final latPadding =
        (bounds.north - bounds.south).abs().clamp(0.002, 0.03).toDouble() * 0.2;
    final lonPadding =
        (bounds.east - bounds.west).abs().clamp(0.002, 0.03).toDouble() * 0.2;

    try {
      final collection = await _marketMapRepository.loadPublished(
        zoom: zoomBucket,
        minLat: bounds.south - latPadding,
        maxLat: bounds.north + latPadding,
        minLon: bounds.west - lonPadding,
        maxLon: bounds.east + lonPadding,
        centerLat: _center.latitude,
        centerLon: _center.longitude,
        maxContainers: _maxRenderedPublishedContainers * 2,
      );
      if (!mounted || serial != _marketMapRequestSerial) return;
      setState(() {
        _marketMapFeatures = collection.features;
        _marketMapRenderCache = null;
        _marketMapLoading = false;
        _lastMarketMapBounds = bounds;
        _lastMarketMapZoomBucket = zoomBucket;
      });
      _runPendingMarketMapRefresh();
    } catch (_) {
      if (!mounted || serial != _marketMapRequestSerial) return;
      setState(() => _marketMapLoading = false);
      _runPendingMarketMapRefresh();
    }
  }

  void _runPendingMarketMapRefresh() {
    if (!_marketMapRefreshPending || !mounted) return;
    _marketMapRefreshPending = false;
    _scheduleMarketMapRefresh(immediate: true);
  }

  void _moveTo(
    LatLng point, {
    double zoom = 16,
    bool immediateReverse = false,
  }) {
    setState(() {
      _center = point;
      _selectedContainer = null;
      _mapMoving = false;
    });

    _mapIdleDebounce?.cancel();
    _mapController.move(point, zoom);
    _scheduleReverse(point, immediate: immediateReverse);
    _scheduleContainersRefresh();
    _scheduleMarketMapRefresh();
  }

  void _onSearchResultSelected(LatLng point, String selectedAddress) {
    _reverseDebounce?.cancel();
    _mapIdleDebounce?.cancel();

    setState(() {
      _center = point;
      _addressPoint = point;
      _selectedContainer = null;
      _mapMoving = false;
    });

    _mapController.move(point, 16.5);
    context.read<DeliveryAddressProvider>().setPickerAddressExplicit(
      address: selectedAddress,
      lat: point.latitude,
      lon: point.longitude,
    );
    _scheduleContainersRefresh();
    _scheduleMarketMapRefresh();
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
      _addressPoint = point;
    });

    _mapController.move(point, 17);
    _scheduleContainersRefresh();
    _scheduleMarketMapRefresh();
  }

  String _containerSubtitle(ContainerRef container) {
    final parts = <String>[
      if (container.number.trim().isNotEmpty)
        'Контейнер: ${container.number.trim()}',
      if (container.passageNumber.trim().isNotEmpty)
        'Проход: ${container.passageNumber.trim()}',
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

  DeliveryPoint _buildPickedPoint({required String hereAddress}) {
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

    final point = _addressPoint ?? _center;

    return DeliveryPoint(
      title: hereAddress.isNotEmpty ? hereAddress : 'Точка на карте',
      subtitle: hereAddress,
      lat: point.latitude,
      lon: point.longitude,
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
    final selectedContainer = SafaMobileMapFeatures.backendDrawingLayersEnabled
        ? _selectedContainer
        : null;

    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final horizontal = AppResponsive.horizontalPadding(context);
    final showLabels = _zoom >= _containerLabelMinZoom;
    final marketMap = SafaMobileMapFeatures.backendDrawingLayersEnabled
        ? _marketMapRenderData()
        : MarketMapRenderData.empty;
    final hasPublishedContainers = marketMap.hasRenderedContainers;
    final showShapes =
        !_mapMoving &&
        _zoom >= _containerShapeMinZoom &&
        (_visibleContainers.length <= _maxRenderedContainerShapes ||
            _zoom >= _containerLabelMinZoom);

    final containerPolygons =
        (SafaMobileMapFeatures.backendDrawingLayersEnabled
                ? _visibleContainers
                : const <ContainerRef>[])
            .where((c) => c.latValue != null && c.lonValue != null)
            .where(
              (c) =>
                  !hasPublishedContainers &&
                  (selectedContainer?.id == c.id || showShapes),
            )
            .map((container) {
              final selected = selectedContainer?.id == container.id;
              return Polygon(
                points: _containerPolygonPoints(
                  container.latValue!,
                  container.lonValue!,
                ),
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.16)
                    : AppColors.white.withValues(alpha: 0.2),
                borderColor: selected
                    ? AppColors.primary
                    : AppColors.textPrimary,
                borderStrokeWidth: selected ? 2.2 : 1.2,
              );
            })
            .toList();

    final markerLimit = MarketMapRenderData.containerRenderLimitForZoom(_zoom);
    final markers =
        (SafaMobileMapFeatures.backendDrawingLayersEnabled
                ? _visibleContainers
                : const <ContainerRef>[])
            .where((c) => c.latValue != null && c.lonValue != null)
            .where(
              (c) =>
                  !_mapMoving ||
                  selectedContainer?.id == c.id ||
                  _visibleContainers.length <= 24,
            )
            .take(
              _mapMoving
                  ? 1
                  : markerLimit.clamp(0, _maxRenderedContainerMarkers),
            )
            .map((container) {
              final selected = selectedContainer?.id == container.id;
              final hideLooseVisual = hasPublishedContainers;
              return SafaMapMarker(
                id: 'picker-container-${container.id}',
                point: LatLng(container.latValue!, container.lonValue!),
                width: ContainerMapMarker.hitSize,
                height: ContainerMapMarker.hitSize,
                alignment: Alignment.center,
                onTap: () => _selectContainer(container),
                visualKey:
                    '$selected-$hideLooseVisual-$showLabels-${container.number}',
                child: hideLooseVisual
                    ? _ContainerTapTarget(
                        container: container,
                        onTap: () => _selectContainer(container),
                      )
                    : ContainerMapMarker(
                        container: container,
                        selected: selected,
                        showLabel: showLabels && !hasPublishedContainers,
                        onTap: () => _selectContainer(container),
                      ),
              );
            })
            .toList();

    final mapMarkers = <SafaMapMarker>[...marketMap.markers, ...markers];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafaYandexMap(
            controller: _mapController,
            initialCenter: _center,
            initialZoom: 15,
            onTap: (point) {
              FocusManager.instance.primaryFocus?.unfocus();
              _moveTo(point, zoom: _zoom, immediateReverse: true);
            },
            onPositionChanged: (position, hasGesture) {
              _center = position.center;

              if (hasGesture) {
                FocusManager.instance.primaryFocus?.unfocus();
                if (!_mapMoving && mounted) {
                  setState(() => _mapMoving = true);
                }
                if (_selectedContainer != null) {
                  setState(() => _selectedContainer = null);
                }
                _scheduleMapIdle(position.center);
              }

              final wasLabelled = _zoom >= _containerLabelMinZoom;
              final isLabelled = position.zoom >= _containerLabelMinZoom;
              final oldZoomBucket = _zoom.floor();
              final newZoomBucket = position.zoom.floor();
              _zoom = position.zoom;
              if ((wasLabelled != isLabelled ||
                      oldZoomBucket != newZoomBucket) &&
                  mounted) {
                setState(() {});
              }

              if (!hasGesture) {
                _scheduleContainersRefresh();
                _scheduleMarketMapRefresh();
              }
            },
            polygons: [...marketMap.polygons, ...containerPolygons],
            polylines: marketMap.polylines,
            markers: mapMarkers,
          ),

          // Центральный маркер выбора — виден, пока контейнер не выбран.
          if (selectedContainer == null)
            const IgnorePointer(child: Center(child: _CenterPin())),

          Positioned(
            top: topInset + AppSpacing.xs,
            left: horizontal,
            right: horizontal,
            child: Column(
              children: [
                AppSearchField(
                  controller: _query,
                  hint: 'Поиск адреса',
                  focusNode: _focus,
                  leading: AppMapActionButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    semanticLabel: 'Назад',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  onChanged: (value) => context
                      .read<DeliveryAutocompleteProvider>()
                      .onQueryChanged(value),
                  onCleared: () => context
                      .read<DeliveryAutocompleteProvider>()
                      .clearSuggestions(),
                ),
                if (autocomplete.loading || autocomplete.items.isNotEmpty) ...[
                  AppSpacing.gapXs,
                  _SuggestionList(
                    loading: autocomplete.loading,
                    items: autocomplete.items,
                    onSelected: (item) {
                      FocusScope.of(context).unfocus();
                      FocusManager.instance.primaryFocus?.unfocus();
                      context
                          .read<DeliveryAutocompleteProvider>()
                          .clearSuggestions();
                      final lat = (item.lat as num).toDouble();
                      final lon = (item.lon as num).toDouble();
                      final addr = (item.address ?? item.title ?? '').toString().trim();
                      _onSearchResultSelected(LatLng(lat, lon), addr);
                    },
                  ),
                ],
                AppSpacing.gapXs,
                if (SafaMobileMapFeatures.backendDrawingLayersEnabled)
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppMapStatusChip(
                      label: _containersLoading
                          ? 'Контейнеры…'
                          : _marketMapLoading
                          ? 'Карта базара…'
                          : 'Контейнеры: ${_visibleContainers.length}',
                      loading: _containersLoading || _marketMapLoading,
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            left: horizontal,
            right: horizontal,
            bottom: AppSpacing.md + bottomInset,
            child: _PickerBottomCard(
              title: widget.title,
              selectedContainer: selectedContainer,
              hereAddress: hereAddress,
              hereLoading: hereLoading,
              hereError: hereError,
              containerSubtitle: selectedContainer == null
                  ? null
                  : _containerSubtitle(selectedContainer),
              containerDetails: selectedContainer == null
                  ? null
                  : _containerDetails(selectedContainer),
              onConfirm:
                  !hereLoading && hereError == null && hereAddress.isNotEmpty
                  ? () => Navigator.of(
                      context,
                    ).pop(_buildPickedPoint(hereAddress: hereAddress))
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  List<LatLng> _containerPolygonPoints(double lat, double lon) {
    const dLat = 0.000055;
    const dLon = 0.000075;

    return [
      LatLng(lat - dLat, lon - dLon),
      LatLng(lat - dLat, lon + dLon),
      LatLng(lat + dLat, lon + dLon),
      LatLng(lat + dLat, lon - dLon),
    ];
  }

  MarketMapRenderData _marketMapRenderData() {
    if (_mapMoving) return MarketMapRenderData.empty;
    final zoomBucket = _zoom.floor();
    final centerLatBucket = (_center.latitude * 10000).round();
    final centerLonBucket = (_center.longitude * 10000).round();
    final featureHash = _marketFeatureHash();
    final cached = _marketMapRenderCache;
    if (cached != null &&
        _marketMapRenderZoomBucket == zoomBucket &&
        _marketMapRenderFeatureCount == _marketMapFeatures.length &&
        _marketMapRenderFeatureHash == featureHash &&
        _marketMapRenderCenterLatBucket == centerLatBucket &&
        _marketMapRenderCenterLonBucket == centerLonBucket &&
        _marketMapRenderMoving == _mapMoving) {
      return cached;
    }

    final next = MarketMapRenderData.fromFeatures(
      _marketMapFeatures,
      zoom: _zoom,
      center: _center,
      maxContainerFeatures: _maxRenderedPublishedContainers,
      showLabels: true,
      districtsOnly: true,
    );
    _marketMapRenderCache = next;
    _marketMapRenderZoomBucket = zoomBucket;
    _marketMapRenderFeatureCount = _marketMapFeatures.length;
    _marketMapRenderFeatureHash = featureHash;
    _marketMapRenderCenterLatBucket = centerLatBucket;
    _marketMapRenderCenterLonBucket = centerLonBucket;
    _marketMapRenderMoving = _mapMoving;
    return next;
  }

  int _marketFeatureHash() {
    var hash = 17;
    for (final feature in _marketMapFeatures) {
      hash = 37 * hash + feature.id.hashCode;
      hash = 37 * hash + feature.kind.hashCode;
      hash = 37 * hash + feature.minZoom;
    }
    return hash;
  }
}

class _ContainerTapTarget extends StatelessWidget {
  const _ContainerTapTarget({required this.container, required this.onTap});

  final ContainerRef container;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label:
          'Контейнер ${container.number}'
          '${container.bazarName.isEmpty ? '' : ', ${container.bazarName}'}',
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.place_rounded, size: 40, color: AppColors.primary),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.35),
            shape: BoxShape.circle,
          ),
        ),
        // Компенсируем высоту иконки, чтобы её острие указывало в центр.
        const SizedBox(height: 40),
      ],
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({
    required this.loading,
    required this.items,
    required this.onSelected,
  });

  final bool loading;
  final List<dynamic> items;
  final void Function(dynamic item) onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.raised,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading) const LinearProgressIndicator(minHeight: 2),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  onTap: () => onSelected(item),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs + 2,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                        AppSpacing.hGapXs,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                item.address as String,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.captionMuted,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerBottomCard extends StatelessWidget {
  const _PickerBottomCard({
    required this.title,
    required this.selectedContainer,
    required this.hereAddress,
    required this.hereLoading,
    required this.hereError,
    required this.containerSubtitle,
    required this.containerDetails,
    required this.onConfirm,
  });

  final String title;
  final ContainerRef? selectedContainer;
  final String hereAddress;
  final bool hereLoading;
  final String? hereError;
  final String? containerSubtitle;
  final String? containerDetails;
  final VoidCallback? onConfirm;

  /// Текст кнопки зависит от того, что именно выбрано.
  String get _actionLabel {
    if (selectedContainer != null) return 'Выбрать контейнер';
    if (title.startsWith('Остановка')) return 'Подтвердить остановку';
    return 'Выбрать точку';
  }

  String get _addressLine {
    if (selectedContainer != null) return containerSubtitle ?? '';
    if (hereLoading) return 'Определяем адрес…';
    if (hereError != null && hereError!.isNotEmpty) return 'Адрес недоступен';
    return hereAddress.isEmpty ? 'Адрес не найден' : hereAddress;
  }

  @override
  Widget build(BuildContext context) {
    final container = selectedContainer;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sheet,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  container == null ? 'Точка на карте' : 'Выбран контейнер',
                  style: AppTypography.label,
                ),
              ),
              if (container != null)
                AppStatusBadge(
                  label: 'Контейнер ${container.number}',
                  tone: AppBadgeTone.success,
                  icon: Icons.inventory_2_outlined,
                  dense: true,
                ),
            ],
          ),
          AppSpacing.gapXxs,
          Text(
            _addressLine,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitle,
          ),
          if (container != null && (containerDetails ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              containerDetails!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionMuted,
            ),
          ],
          AppSpacing.gapSm,
          AppPrimaryButton(
            label: _actionLabel,
            size: AppButtonSize.medium,
            onPressed: onConfirm,
            loading: hereLoading,
            loadingLabel: 'Определяем адрес…',
          ),
        ],
      ),
    );
  }
}
