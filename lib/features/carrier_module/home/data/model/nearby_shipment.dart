class NearbyShipment {
  final int id;
  final String publicCode;
  final String status;
  final String title;
  final String serviceType;
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

  final String? clientFirstName;
  final String? clientPhone;
  final String? clientAvatarUrl;

  final int distanceM;

  const NearbyShipment({
    required this.id,
    required this.publicCode,
    required this.status,
    required this.title,
    required this.serviceType,
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
    this.clientFirstName,
    this.clientPhone,
    this.clientAvatarUrl,
  });

  int get displayFare => finalFare > 0 ? finalFare : (estimatedFare ?? 0);

  String get serviceLabel {
    switch (serviceType) {
      case 'cars':
        return 'Тачки';
      case 'amanat':
        return 'Аманат';
      case 'delivery':
        return 'Доставка';
      default:
        final name = segment?.name.trim() ?? '';
        return name.isNotEmpty ? name : 'Заказ';
    }
  }

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
    return DateTime.tryParse(v.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
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
      serviceType: _asString(json['service_type']),
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
      clientFirstName: json['client_first_name']?.toString(),
      clientPhone: json['client_phone']?.toString(),
      clientAvatarUrl: json['client_avatar_url']?.toString(),
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
  final String? district;
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
    this.district,
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

  static String? _clean(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static String? _pickContainer(Map<String, dynamic> json) {
    return _clean(json['container_number']) ??
        _clean(json['container']) ??
        _clean(json['container_label']);
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
      bazar: _clean(json['bazar']),
      district: _clean(json['district']),
      passage: _clean(json['passage']),
      container: _pickContainer(json),
      lat: _asDouble(json['lat']),
      lon: _asDouble(json['lon']),
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
    if (parts.isNotEmpty) return parts.join(' · ');
    return title.trim().isNotEmpty ? title.trim() : 'Точка';
  }

  String get headerLine {
    final parts = <String>[];
    final b = (bazar ?? '').trim();
    final d = (district ?? '').trim();
    if (b.isNotEmpty) parts.add('Базар: $b');
    if (d.isNotEmpty) parts.add('Район: $d');
    if (parts.isNotEmpty) return parts.join(' · ');

    final p = (passage ?? '').trim();
    final c = (container ?? '').trim();
    if (p.isNotEmpty) parts.add('Проход: $p');
    if (c.isNotEmpty) parts.add('Контейнер: $c');
    return parts.isNotEmpty
        ? parts.join(' · ')
        : (title.trim().isNotEmpty ? title.trim() : 'Точка');
  }

  String get subLine {
    final parts = <String>[];
    final p = (passage ?? '').trim();
    final c = (container ?? '').trim();
    if (p.isNotEmpty) parts.add('Проход: $p');
    if (c.isNotEmpty) parts.add('Контейнер: $c');
    return parts.join(' · ');
  }

  String get shortHint => compactAddress;
}
