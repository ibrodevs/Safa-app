class NearbyShipment {
  final int id;
  final String publicCode;
  final String title;
  final int estimatedFare;
  final int quantity;
  final bool fragile;
  final String status;
  final DateTime createdAt;
  final int distanceM;
  final List<NearbyShipmentStop> stops;

  NearbyShipment({
    required this.id,
    required this.publicCode,
    required this.title,
    required this.estimatedFare,
    required this.quantity,
    required this.fragile,
    required this.status,
    required this.createdAt,
    required this.distanceM,
    required this.stops,
  });

  factory NearbyShipment.fromJson(Map<String, dynamic> json) {
    return NearbyShipment(
      id: json['id'] as int,
      publicCode: json['public_code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      estimatedFare: json['estimated_fare'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      fragile: json['fragile'] as bool? ?? false,
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      distanceM: json['distance_m'] as int? ?? 0,
      stops: (json['stops'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(NearbyShipmentStop.fromJson)
          .toList(),
    );
  }
}

class NearbyShipmentStop {
  final int position;
  final String title;

  final String? bazar;
  final String? passage;
  final String? container;

  final double lat;
  final double lon;

  NearbyShipmentStop({
    required this.position,
    required this.title,
    required this.lat,
    required this.lon,
    this.bazar,
    this.passage,
    this.container,
  });

  static String? _pickContainer(Map<String, dynamic> json) {
    final a = json['container_number']?.toString();
    if (a != null && a.trim().isNotEmpty) return a.trim();
    final b = json['container_label']?.toString();
    if (b != null && b.trim().isNotEmpty) return b.trim();
    final c = json['container']?.toString();
    if (c != null && c.trim().isNotEmpty) return c.trim();
    return null;
  }

  factory NearbyShipmentStop.fromJson(Map<String, dynamic> json) {
    return NearbyShipmentStop(
      position: json['position'] as int? ?? 0,
      title: json['title']?.toString() ?? '',
      bazar: json['bazar']?.toString(),
      passage: json['passage']?.toString(),
      container: _pickContainer(json),
      lat: double.tryParse(json['lat']?.toString() ?? '') ?? 0,
      lon: double.tryParse(json['lon']?.toString() ?? '') ?? 0,
    );
  }

  String get headerLine {
    final c = (container ?? '').trim();
    final p = (passage ?? '').trim();
    if (c.isNotEmpty && p.isNotEmpty) return 'Контейнер $c, $p проход';
    if (c.isNotEmpty) return 'Контейнер $c';
    if (p.isNotEmpty) return '$p проход';
    return title.isNotEmpty ? title : 'Точка';
  }

  String get subLine {
    final b = (bazar ?? '').trim();
    return b.isNotEmpty ? b : '';
  }

  String get shortHint {
    final p = (passage ?? '').trim();
    final c = (container ?? '').trim();
    final parts = <String>[];
    if (p.isNotEmpty) parts.add('$p проход');
    if (c.isNotEmpty) parts.add('$c контейнер');
    return parts.join(', ');
  }
}
