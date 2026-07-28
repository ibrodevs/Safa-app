from pathlib import Path


path = Path("lib/features/main_module/map/view/map_screen.dart")
text = path.read_text(encoding="utf-8")


def replace_once(old: str, new: str) -> None:
    global text
    if new in text:
        return
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"Expected one match, found {count}: {old[:80]!r}")
    text = text.replace(old, new, 1)


replace_once(
    "import '../data/model/delivery_refs_models.dart';\n"
    "import '../data/model/shipment_status.dart';\n"
    "import '../data/repo/delivery_refs_repository.dart';",
    "import '../data/model/delivery_refs_models.dart';\n"
    "import '../data/model/market_map_feature.dart';\n"
    "import '../data/model/shipment_status.dart';\n"
    "import '../data/repo/delivery_refs_repository.dart';\n"
    "import '../data/repo/market_map_repository.dart';",
)

replace_once(
    "import 'widgets/container_map_marker.dart';\n"
    "import 'widgets/here_bubble.dart';",
    "import 'widgets/container_map_marker.dart';\n"
    "import 'widgets/here_bubble.dart';\n"
    "import 'widgets/market_map_layers.dart';",
)

replace_once(
    "  final DeliveryRefsRepository _refsRepository = DeliveryRefsRepository();\n"
    "  final TextEditingController _descriptionController = TextEditingController();",
    "  final DeliveryRefsRepository _refsRepository = DeliveryRefsRepository();\n"
    "  final MarketMapRepository _marketMapRepository = MarketMapRepository();\n"
    "  final TextEditingController _descriptionController = TextEditingController();",
)

replace_once(
    "  List<ContainerRef> _visibleContainers = const [];\n"
    "  ContainerRef? _selectedContainer;\n"
    "  bool _containersLoading = false;\n"
    "  int _containersRequestSerial = 0;",
    "  List<ContainerRef> _visibleContainers = const [];\n"
    "  ContainerRef? _selectedContainer;\n"
    "  bool _containersLoading = false;\n"
    "  int _containersRequestSerial = 0;\n\n"
    "  List<MarketMapFeature> _marketMapFeatures = const [];\n"
    "  bool _marketMapLoading = false;\n"
    "  int _marketMapRequestSerial = 0;",
)

replace_once(
    "  void _fitToPoints(List<LatLng> pts) {",
    "  Future<void> _loadMarketMap() async {\n"
    "    if (_marketMapLoading) return;\n"
    "    final serial = ++_marketMapRequestSerial;\n"
    "    _marketMapLoading = true;\n\n"
    "    try {\n"
    "      final collection = await _marketMapRepository.loadPublished();\n"
    "      if (!mounted || serial != _marketMapRequestSerial) return;\n"
    "      setState(() {\n"
    "        _marketMapFeatures = collection.features;\n"
    "        _marketMapLoading = false;\n"
    "      });\n"
    "    } catch (_) {\n"
    "      if (!mounted || serial != _marketMapRequestSerial) return;\n"
    "      setState(() => _marketMapLoading = false);\n"
    "    }\n"
    "  }\n\n"
    "  void _fitToPoints(List<LatLng> pts) {",
)

replace_once(
    "    WidgetsBinding.instance.addPostFrameCallback((_) async {\n"
    "      if (!mounted) return;\n\n"
    "      final p = context.read<ActiveShipmentProvider>();",
    "    WidgetsBinding.instance.addPostFrameCallback((_) async {\n"
    "      if (!mounted) return;\n\n"
    "      unawaited(_loadMarketMap());\n"
    "      final p = context.read<ActiveShipmentProvider>();",
)

replace_once(
    "  void _reorderIntermediatePoints(int oldIndex, int newIndex) {\n"
    "    setState(() {\n"
    "      final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;\n"
    "      final point = _intermediatePoints.removeAt(oldIndex);\n"
    "      _intermediatePoints.insert(adjusted, point);\n"
    "    });\n"
    "  }",
    "  void _reorderIntermediatePoints(int oldIndex, int newIndex) {\n"
    "    setState(() {\n"
    "      final point = _intermediatePoints.removeAt(oldIndex);\n"
    "      _intermediatePoints.insert(newIndex, point);\n"
    "    });\n"
    "  }",
)

replace_once(
    "    final markers = <Marker>[];\n"
    "    final containerPolygons = <Polygon>[];",
    "    final markers = <Marker>[];\n"
    "    final containerPolygons = <Polygon>[];\n"
    "    final marketMap = MarketMapRenderData.fromFeatures(\n"
    "      _marketMapFeatures,\n"
    "      zoom: _zoom,\n"
    "    );",
)

replace_once(
    "          final wasLabelled = _zoom >= _containerLabelMinZoom;\n"
    "          final isLabelled = pos.zoom >= _containerLabelMinZoom;\n"
    "          _zoom = pos.zoom;\n"
    "          if (wasLabelled != isLabelled && mounted) setState(() {});",
    "          final wasLabelled = _zoom >= _containerLabelMinZoom;\n"
    "          final oldZoomBucket = _zoom.floor();\n"
    "          final isLabelled = pos.zoom >= _containerLabelMinZoom;\n"
    "          final newZoomBucket = pos.zoom.floor();\n"
    "          _zoom = pos.zoom;\n"
    "          if ((wasLabelled != isLabelled ||\n"
    "                  oldZoomBucket != newZoomBucket) &&\n"
    "              mounted) {\n"
    "            setState(() {});\n"
    "          }",
)

replace_once(
    "        if (containerPolygons.isNotEmpty)\n"
    "          PolygonLayer(polygons: containerPolygons),",
    "        if (marketMap.polygons.isNotEmpty)\n"
    "          PolygonLayer(polygons: marketMap.polygons),\n"
    "        if (marketMap.polylines.isNotEmpty)\n"
    "          PolylineLayer(polylines: marketMap.polylines),\n"
    "        if (containerPolygons.isNotEmpty)\n"
    "          PolygonLayer(polygons: containerPolygons),",
)

path.write_text(text, encoding="utf-8")
print(f"Updated {path}")
