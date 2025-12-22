import 'nearby_shipment.dart';

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
