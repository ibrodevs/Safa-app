from pathlib import Path
import re
from textwrap import dedent


def replace_once(path: str, old: str, new: str, label: str) -> None:
    p = Path(path)
    source = p.read_text()
    if old not in source:
        raise RuntimeError(f"{label}: source snippet not found")
    p.write_text(source.replace(old, new, 1))


# Client route summary: no raw long address if Safa hierarchy is available.
replace_once(
    "lib/features/main_module/map/view/components/order_summary_sheet.dart",
    "                    title: stops[i].title,\n                    subtitle: stops[i].subtitle,",
    "                    title: stops[i].compactTitle,\n                    subtitle: stops[i].compactSubtitle,",
    "order summary route labels",
)

# Role-aware notifications routing.
replace_once(
    "lib/core/router/app_router.dart",
    "      GoRoute(\n        path: '/profile/notifications',\n        pageBuilder: (context, state) =>\n            _build(state, const ProfileNotificationsScreen()),\n      ),",
    "      GoRoute(\n        path: '/profile/notifications',\n        pageBuilder: (context, state) {\n          final role = state.uri.queryParameters['role'] ?? 'client';\n          return _build(state, ProfileNotificationsScreen(role: role));\n        },\n      ),",
    "notification route",
)
replace_once(
    "lib/features/carrier_module/profile/view/carrier_profile_screen.dart",
    "onTap: () => context.push('/profile/notifications'),",
    "onTap: () => context.push('/profile/notifications?role=carrier'),",
    "carrier notification route",
)

# Clean notifications UI and hide carrier-only settings from clients.
p = Path("lib/features/main_module/profile/view/components/profile_notifications_screen.dart")
s = p.read_text()
old = "class ProfileNotificationsScreen extends StatefulWidget {\n  const ProfileNotificationsScreen({super.key});"
new = "class ProfileNotificationsScreen extends StatefulWidget {\n  const ProfileNotificationsScreen({super.key, this.role = 'client'});\n\n  final String role;\n  bool get isCarrier => role == 'carrier';"
if old not in s:
    raise RuntimeError("notification screen constructor not found")
s = s.replace(old, new, 1)
old = """                                  _SwitchTile(
                                    title: 'Новые заказы рядом',
                                    subtitle:
                                        'Когда появляется новый груз поблизости.',
                                    value: _newShipments,
                                    onChanged: (v) =>
                                        setState(() => _newShipments = v),
                                  ),
                                  const _SettingsDivider(),
"""
new = """                                  if (widget.isCarrier) ...[
                                    _SwitchTile(
                                      title: 'Новые заказы рядом',
                                      subtitle:
                                          'Когда появляется подходящий заказ поблизости.',
                                      value: _newShipments,
                                      onChanged: (v) =>
                                          setState(() => _newShipments = v),
                                    ),
                                    const _SettingsDivider(),
                                  ],
"""
if old not in s:
    raise RuntimeError("carrier-only notification setting not found")
s = s.replace(old, new, 1)
source_block = """                            const SizedBox(height: 10),
                            Text(
                              'Источник: сервер',
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                                color: AppColors.grey,
                              ),
                            ),
"""
if source_block not in s:
    raise RuntimeError("notification source hint not found")
s = s.replace(source_block, "", 1)
tags_pattern = re.compile(
    r"                    if \(n\.channel\.isNotEmpty \|\| n\.type\.isNotEmpty\) \.\.\.\[.*?                    \],\n",
    re.S,
)
if not tags_pattern.search(s):
    raise RuntimeError("technical notification tags not found")
clean_meta = """                    const SizedBox(height: 10),
                    Text(
                      n.isRead ? 'Прочитано' : 'Новое',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.0,
                        fontWeight: FontWeight.w800,
                        color: n.isRead ? AppColors.grey : AppColors.accent,
                      ),
                    ),
"""
s = tags_pattern.sub(clean_meta, s, count=1)
tag_class = re.compile(
    r"\nclass _Tag extends StatelessWidget \{.*?\n\}\n\nclass _UnreadPill",
    re.S,
)
if not tag_class.search(s):
    raise RuntimeError("_Tag class not found")
s = tag_class.sub("\nclass _UnreadPill", s, count=1)
p.write_text(s)

# Specialist map and order UI.
p = Path("lib/features/carrier_module/home/carrier_home_screen.dart")
s = p.read_text()
old = """  bool _marketMapLoading = false;
  int? _marketMapPointsHash;
  List<MarketMapFeature> _marketMapFeatures = const [];
  MarketMapRenderData? _marketMapRenderCache;
"""
new = """  bool _marketMapLoading = false;
  bool _marketMapViewportLoading = false;
  int? _marketMapPointsHash;
  List<MarketMapFeature> _marketMapFeatures = const [];
  MarketMapRenderData? _marketMapRenderCache;
  Timer? _marketMapViewportDebounce;
  LatLngBounds? _lastMarketMapViewportBounds;
  int? _lastMarketMapViewportZoomBucket;
  int _marketMapViewportRequestSerial = 0;
"""
if old not in s:
    raise RuntimeError("carrier map state block not found")
s = s.replace(old, new, 1)
old = """    _pollTimer?.cancel();
    _nearbyPollTimer?.cancel();
    _posSub?.cancel();
    super.dispose();
"""
new = """    _pollTimer?.cancel();
    _nearbyPollTimer?.cancel();
    _marketMapViewportDebounce?.cancel();
    _posSub?.cancel();
    super.dispose();
"""
if old not in s:
    raise RuntimeError("carrier dispose block not found")
s = s.replace(old, new, 1)
old = "    final fare = (j['estimated_fare'] as num?)?.toInt() ?? 0;"
new = "    final estimatedFare = (j['estimated_fare'] as num?)?.toInt() ?? 0;\n    final finalFare = (j['final_fare'] as num?)?.toInt() ?? 0;\n    final fare = finalFare > 0 ? finalFare : estimatedFare;"
if old not in s:
    raise RuntimeError("active fare parser not found")
s = s.replace(old, new, 1)

anchor = "  List<_CarrierPassageLine> _passageLines() {"
if anchor not in s:
    raise RuntimeError("passage anchor not found")
viewport_code = dedent("""
  void _scheduleMarketMapViewportRefresh({bool immediate = false}) {
    _marketMapViewportDebounce?.cancel();
    _marketMapViewportDebounce = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 420),
      _refreshMarketMapForViewport,
    );
  }

  bool _shouldReloadMarketMapBounds(
    LatLngBounds previous,
    LatLngBounds next,
  ) {
    final latSpan = (previous.north - previous.south).abs();
    final lonSpan = (previous.east - previous.west).abs();
    final latShift =
        (previous.center.latitude - next.center.latitude).abs();
    final lonShift =
        (previous.center.longitude - next.center.longitude).abs();
    return latShift > latSpan * 0.25 || lonShift > lonSpan * 0.25;
  }

  Future<void> _refreshMarketMapForViewport() async {
    if (!mounted || _marketMapViewportLoading) return;

    late final LatLngBounds bounds;
    try {
      bounds = _mapController.camera.visibleBounds;
    } catch (_) {
      return;
    }

    final zoomBucket = _zoom.floor();
    final previous = _lastMarketMapViewportBounds;
    if (previous != null &&
        _lastMarketMapViewportZoomBucket == zoomBucket &&
        !_shouldReloadMarketMapBounds(previous, bounds)) {
      return;
    }

    final serial = ++_marketMapViewportRequestSerial;
    final latPadding =
        (bounds.north - bounds.south).abs().clamp(0.002, 0.03) * 0.2;
    final lonPadding =
        (bounds.east - bounds.west).abs().clamp(0.002, 0.03) * 0.2;
    _marketMapViewportLoading = true;
    try {
      final collection = await _marketMapRepository.loadPublished(
        zoom: zoomBucket,
        minLat: bounds.south - latPadding,
        maxLat: bounds.north + latPadding,
        minLon: bounds.west - lonPadding,
        maxLon: bounds.east + lonPadding,
        centerLat: bounds.center.latitude,
        centerLon: bounds.center.longitude,
        maxContainers: 192,
      );
      if (!mounted || serial != _marketMapViewportRequestSerial) return;
      setState(() {
        _marketMapFeatures = collection.features;
        _marketMapRenderCache = null;
        _lastMarketMapViewportBounds = bounds;
        _lastMarketMapViewportZoomBucket = zoomBucket;
        _marketMapPointsHash = null;
      });
    } catch (_) {
      // Keep last map snapshot on transient network errors.
    } finally {
      _marketMapViewportLoading = false;
    }
  }

""")
s = s.replace(anchor, viewport_code + anchor, 1)
old = """            options: MapOptions(
              initialCenter: LatLng(_centerLat, _centerLon),
              initialZoom: 15,
              onPositionChanged: (pos, hasGesture) {
                _centerLat = pos.center.latitude;
                _centerLon = pos.center.longitude;
                final oldZoomBucket = _zoom.floor();
                _zoom = pos.zoom;
                if (oldZoomBucket != _zoom.floor()) {
                  _marketMapRenderCache = null;
                  if (mounted) setState(() {});
                }
              },
            ),
"""
new = """            options: MapOptions(
              initialCenter: LatLng(_centerLat, _centerLon),
              initialZoom: 15,
              onMapReady: () =>
                  _scheduleMarketMapViewportRefresh(immediate: true),
              onPositionChanged: (pos, hasGesture) {
                _centerLat = pos.center.latitude;
                _centerLon = pos.center.longitude;
                final oldZoomBucket = _zoom.floor();
                _zoom = pos.zoom;
                if (oldZoomBucket != _zoom.floor()) {
                  _marketMapRenderCache = null;
                  if (mounted) setState(() {});
                }
                _scheduleMarketMapViewportRefresh();
              },
            ),
"""
if old not in s:
    raise RuntimeError("carrier MapOptions block not found")
s = s.replace(old, new, 1)

shipment_sheet = dedent("""
class _ShipmentSheet extends StatelessWidget {
  const _ShipmentSheet({
    required this.shipment,
    required this.accent,
    required this.routeLoading,
    required this.onAccept,
    required this.onReject,
  });

  final NearbyShipment shipment;
  final Color accent;
  final bool routeLoading;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final distance = shipment.distanceM;
    final distanceText = distance >= 1000
        ? '${(distance / 1000).toStringAsFixed(1)} км'
        : '$distance м';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shipment.serviceLabel,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              Text(
                '${shipment.displayFare} сом',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '$distanceText от вас · ${shipment.stops.length} точек',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9FA4AD),
            ),
          ),
          if (shipment.stops.isNotEmpty) ...[
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 170),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < shipment.stops.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i == shipment.stops.length - 1 ? 0 : 9,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                shipment.stops[i].compactAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.25,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (routeLoading) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Забрать заказ',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Отказать',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
""").strip()
pattern = re.compile(
    r"class _ShipmentSheet extends StatelessWidget \{.*?\n\}\n\nclass _ActiveProgressSheet",
    re.S,
)
if not pattern.search(s):
    raise RuntimeError("_ShipmentSheet block not found")
s = pattern.sub(shipment_sheet + "\n\nclass _ActiveProgressSheet", s, count=1)

stop_ui = dedent("""
class _StopUi {
  final String title;
  final String? bazar;
  final String? district;
  final String? passage;
  final String? container;
  final double? lat;
  final double? lon;

  _StopUi({
    required this.title,
    required this.lat,
    required this.lon,
    this.bazar,
    this.district,
    this.passage,
    this.container,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    final d = double.tryParse(v.toString());
    if (d == null || !d.isFinite) return null;
    if (d.abs() > 1e9) return null;
    return d;
  }

  static String? _clean(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static String? _pickContainer(Map<String, dynamic> json) {
    return _clean(json['container_number']) ??
        _clean(json['container']) ??
        _clean(json['container_label']);
  }

  factory _StopUi.fromJson(Map<String, dynamic> j) {
    return _StopUi(
      title: (j['title'] ?? '').toString(),
      bazar: _clean(j['bazar']),
      district: _clean(j['district']),
      passage: _clean(j['passage']),
      container: _pickContainer(j),
      lat: _toDouble(j['lat']),
      lon: _toDouble(j['lon']),
    );
  }

  factory _StopUi.fromNearby(NearbyShipmentStop s) {
    return _StopUi(
      title: s.title,
      bazar: s.bazar,
      district: s.district,
      passage: s.passage,
      container: s.container,
      lat: s.lat,
      lon: s.lon,
    );
  }

  String get compactAddress {
    final parts = <String>[];
    final b = (bazar ?? '').trim();
    final d = (district ?? '').trim();
    final p = (passage ?? '').trim();
    final c = (container ?? '').trim();
    if (b.isNotEmpty) parts.add('Базар: $b');
    if (d.isNotEmpty) parts.add('Район: $d');
    if (p.isNotEmpty) parts.add('Проход: $p');
    if (c.isNotEmpty) parts.add('Контейнер: $c');
    return parts.isNotEmpty
        ? parts.join(' · ')
        : (title.trim().isNotEmpty ? title.trim() : 'Точка');
  }

  String get headerLine {
    final parts = <String>[];
    final b = (bazar ?? '').trim();
    final d = (district ?? '').trim();
    if (b.isNotEmpty) parts.add('Базар: $b');
    if (d.isNotEmpty) parts.add('Район: $d');
    if (parts.isNotEmpty) return parts.join(' · ');
    return compactAddress;
  }

  String get subLine {
    final parts = <String>[];
    final p = (passage ?? '').trim();
    final c = (container ?? '').trim();
    if (p.isNotEmpty) parts.add('Проход: $p');
    if (c.isNotEmpty) parts.add('Контейнер: $c');
    return parts.join(' · ');
  }

  String get shortLine => compactAddress;
}
""").strip()
pattern = re.compile(r"class _StopUi \{.*?\n\}\n\nclass _ActiveUi", re.S)
if not pattern.search(s):
    raise RuntimeError("_StopUi block not found")
s = pattern.sub(stop_ui + "\n\nclass _ActiveUi", s, count=1)
old = """              Text(title, style: titleStyle),
              const SizedBox(height: 4),
              Text(subtitle, style: subStyle),
"""
new = """              Text(title, style: titleStyle),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: subStyle),
              ],
"""
if old not in s:
    raise RuntimeError("stop row subtitle block not found")
s = s.replace(old, new, 1)
p.write_text(s)

# Regression contract tests.
Path("test/order_role_map_notifications_contract_test.dart").write_text(
    """import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('client and specialist use compact hierarchy and server fare', () {
    final nearby = File('lib/features/carrier_module/home/data/model/nearby_shipment.dart').readAsStringSync();
    final carrier = File('lib/features/carrier_module/home/carrier_home_screen.dart').readAsStringSync();
    final point = File('lib/features/main_module/map/data/model/delivery_point_model.dart').readAsStringSync();
    final summary = File('lib/features/main_module/map/view/components/order_summary_sheet.dart').readAsStringSync();
    expect(nearby, contains('final String? district;'));
    expect(nearby, contains('String get compactAddress'));
    expect(nearby, contains('int get displayFare'));
    expect(carrier, contains(\"j['final_fare']\"));
    expect(carrier, contains('shipment.displayFare'));
    expect(carrier, contains('shipment.stops[i].compactAddress'));
    expect(point, contains('String get compactTitle'));
    expect(summary, contains('title: stops[i].compactTitle'));
  });

  test('specialist map refreshes published containers for viewport', () {
    final source = File('lib/features/carrier_module/home/carrier_home_screen.dart').readAsStringSync();
    expect(source, contains('_refreshMarketMapForViewport'));
    expect(source, contains('onMapReady:'));
    expect(source, contains('maxContainers: 192'));
  });

  test('notifications are role-aware and hide technical tags', () {
    final screen = File('lib/features/main_module/profile/view/components/profile_notifications_screen.dart').readAsStringSync();
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    final profile = File('lib/features/carrier_module/profile/view/carrier_profile_screen.dart').readAsStringSync();
    expect(screen, contains('if (widget.isCarrier)'));
    expect(screen, isNot(contains('class _Tag extends StatelessWidget')));
    expect(screen, isNot(contains('Источник: сервер')));
    expect(router, contains(\"queryParameters['role'] ?? 'client'\"));
    expect(profile, contains('/profile/notifications?role=carrier'));
  });
}
"""
)
