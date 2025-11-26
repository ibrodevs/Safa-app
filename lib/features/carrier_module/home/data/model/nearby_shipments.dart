class NearbyShipmentsPage {
  final int count;
  final List<NearbyShipment> results;

  NearbyShipmentsPage({
    required this.count,
    required this.results,
  });

  factory NearbyShipmentsPage.fromJson(Map<String, dynamic> json) {
    final results = (json['results'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(NearbyShipment.fromJson)
        .toList();

    return NearbyShipmentsPage(
      count: json['count'] is int ? json['count'] as int : results.length,
      results: results,
    );
  }
}

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
  final double lat;
  final double lon;

  NearbyShipmentStop({
    required this.position,
    required this.title,
    required this.lat,
    required this.lon,
  });

  factory NearbyShipmentStop.fromJson(Map<String, dynamic> json) {
    return NearbyShipmentStop(
      position: json['position'] as int? ?? 0,
      title: json['title']?.toString() ?? '',
      lat: double.tryParse(json['lat']?.toString() ?? '') ?? 0,
      lon: double.tryParse(json['lon']?.toString() ?? '') ?? 0,
    );
  }
}
