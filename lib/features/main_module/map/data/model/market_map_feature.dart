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
  int get zIndex => _asInt(properties['z_index'], fallback: 1);
  String get linePattern => (properties['line_pattern'] ?? 'solid')
      .toString()
      .trim()
      .toLowerCase();

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
      minZoom: _clampInt(_asInt(properties['min_zoom'], fallback: 0), 0, 22),
      strokeColor: (properties['stroke_color'] ?? '#E47F26').toString(),
      fillColor: (properties['fill_color'] ?? '#FF8656').toString(),
      strokeWidth: _clampDouble(
        _asDouble(properties['stroke_width'], fallback: 2),
        1,
        12,
      ),
      fillOpacity: _clampDouble(
        _asDouble(properties['fill_opacity'], fallback: 0.2),
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

  static int _clampInt(int value, int minimum, int maximum) {
    if (value < minimum) return minimum;
    if (value > maximum) return maximum;
    return value;
  }

  static double _clampDouble(double value, double minimum, double maximum) {
    if (value < minimum) return minimum;
    if (value > maximum) return maximum;
    return value;
  }
}

final class MarketMapCollection {
  const MarketMapCollection({required this.features, required this.versions});

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
