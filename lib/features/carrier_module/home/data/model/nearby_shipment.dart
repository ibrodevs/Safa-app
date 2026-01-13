class NearbyShipment {
  final int id;
  final String publicCode;
  final String status;
  final String title;
  final NearbyShipmentSegment? segment;

  final String size;
  final int quantity;
  final bool fragile;
  final String description;

  final String stopsCount;
  final List<NearbyShipmentStop> stops;

  final int? estimatedFare;
  final int finalFare;
  final String commission;
  final String courierIncome;

  final DateTime createdAt;
  final DateTime? finishedAt;

  final bool isPaid;
  final DateTime? paidAt;

  final int distanceM;

  const NearbyShipment({
    required this.id,
    required this.publicCode,
    required this.status,
    required this.title,
    required this.segment,
    required this.size,
    required this.quantity,
    required this.fragile,
    required this.description,
    required this.stops,
    required this.stopsCount,
    required this.estimatedFare,
    required this.finalFare,
    required this.commission,
    required this.courierIncome,
    required this.createdAt,
    required this.finishedAt,
    required this.isPaid,
    required this.paidAt,
    required this.distanceM,
  });

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static int? _asNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static String _asString(dynamic v) => v?.toString() ?? '';

  static DateTime _asDateTime(dynamic v) {
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.tryParse(v.toString()) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _asNullableDateTime(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory NearbyShipment.fromJson(Map<String, dynamic> json) {
    final seg = json['segment'];
    NearbyShipmentSegment? segment;
    if (seg is Map) {
      segment = NearbyShipmentSegment.fromJson(Map<String, dynamic>.from(seg));
    }

    final rawStops = json['stops'] as List? ?? const [];
    final stops = rawStops
        .whereType<Map>()
        .map((e) => NearbyShipmentStop.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return NearbyShipment(
      id: _asInt(json['id']),
      publicCode: _asString(json['public_code']),
      status: _asString(json['status']),
      title: _asString(json['title']),

      segment: segment,

      size: _asString(json['size']),
      quantity: _asInt(json['quantity']),
      fragile: json['fragile'] == true,
      description: _asString(json['description']),

      stops: stops,
      stopsCount: _asString(json['stops_count']),

      estimatedFare: _asNullableInt(json['estimated_fare']),
      finalFare: _asInt(json['final_fare']),
      commission: _asString(json['commission']),
      courierIncome: _asString(json['courier_income']),

      createdAt: _asDateTime(json['created_at']),
      finishedAt: _asNullableDateTime(json['finished_at']),

      isPaid: json['is_paid'] == true,
      paidAt: _asNullableDateTime(json['paid_at']),

      distanceM: _asInt(json['distance_m']),
    );
  }
}

class NearbyShipmentSegment {
  final int id;
  final String name;
  final String icon;
  final String description;

  const NearbyShipmentSegment({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });

  factory NearbyShipmentSegment.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    String asString(dynamic v) => v?.toString() ?? '';

    return NearbyShipmentSegment(
      id: asInt(json['id']),
      name: asString(json['name']),
      icon: asString(json['icon']),
      description: asString(json['description']),
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

  static double _asDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(',', '.');
    return double.tryParse(s) ?? 0;
  }

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
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return NearbyShipmentStop(
      position: asInt(json['position']),
      title: (json['title'] ?? '').toString(),
      bazar: json['bazar']?.toString(),
      passage: json['passage']?.toString(),
      container: _pickContainer(json),
      lat: _asDouble(json['lat']),
      lon: _asDouble(json['lon']),
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
