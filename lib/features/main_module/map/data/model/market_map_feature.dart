final class MarketMapFeature {
  const MarketMapFeature({
    required this.id,
    required this.kind,
    required this.name,
    required this.geometryType,
    required this.coordinates,
    required this.minZoom,
    required this.strokeColor,
    required this.fillColor,
    required this.strokeWidth,
    required this.fillOpacity,
    required this.properties,
  });

  final String id;
  final String kind;
  final String name;
  final String geometryType;
  final dynamic coordinates;
  final int minZoom;
  final String strokeColor;
  final String fillColor;
  final double strokeWidth;
  final double fillOpacity;
  final Map<String, dynamic> properties;

  bool get isContainer => kind == 'container';

  factory MarketMapFeature.fromJson(Map<String, dynamic> json) {
    final rawProperties = json['properties'];
    final properties = rawProperties is Map
        ? Map<String, dynamic>.from(rawProperties)
        : <String, dynamic>{};
    final rawGeometry = json['geometry'];
    final geometry = rawGeometry is Map
        ? Map<String, dynamic>.from(rawGeometry)
        : <String, dynamic>{};

    return MarketMapFeature(
      id: (json['id'] ?? '').toString(),
      kind: (properties['kind'] ?? '').toString().trim().toLowerCase(),
      name: (properties['name'] ?? properties['number'] ?? '').toString(),
      geometryType: (geometry['type'] ?? '').toString(),
      coordinates: geometry['coordinates'],
      minZoom: _asInt(properties['min_zoom'], fallback: 0).clamp(0, 22),
      strokeColor: (properties['stroke_color'] ?? '#E47F26').toString(),
      fillColor: (properties['fill_color'] ?? '#FF8656').toString(),
      strokeWidth: _asDouble(properties['stroke_width'], fallback: 2).clamp(
        1,
        12,
      ),
      fillOpacity: _asDouble(properties['fill_opacity'], fallback: 0.2).clamp(
        0,
        1,
      ),
      properties: properties,
    );
  }

  static int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _asDouble(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

final class MarketMapCollection {
  const MarketMapCollection({
    required this.features,
    required this.versions,
  });

  final List<MarketMapFeature> features;
  final Map<String, int> versions;

  factory MarketMapCollection.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    final features = <MarketMapFeature>[];
    if (rawFeatures is List) {
      for (final raw in rawFeatures) {
        if (raw is! Map) continue;
        try {
          features.add(
            MarketMapFeature.fromJson(Map<String, dynamic>.from(raw)),
          );
        } catch (_) {
          // Один повреждённый объект не должен скрывать всю опубликованную карту.
        }
      }
    }

    final versions = <String, int>{};
    final rawVersions = json['versions'];
    if (rawVersions is Map) {
      for (final entry in rawVersions.entries) {
        final value = entry.value;
        final parsed = value is num
            ? value.toInt()
            : int.tryParse(value?.toString() ?? '');
        if (parsed != null) versions[entry.key.toString()] = parsed;
      }
    }

    return MarketMapCollection(features: features, versions: versions);
  }
}
