import 'package:flutter/foundation.dart';

@immutable
class ShipmentHistoryItem {
  final int id;
  final String publicCode;
  final String title;
  final int estimatedFare;
  final String sizeLabel;
  final int quantity;
  final bool fragile;
  final String stopsCount;
  final String pickup;
  final String status;
  final DateTime createdAt;

  const ShipmentHistoryItem({
    required this.id,
    required this.publicCode,
    required this.title,
    required this.estimatedFare,
    required this.sizeLabel,
    required this.quantity,
    required this.fragile,
    required this.stopsCount,
    required this.pickup,
    required this.status,
    required this.createdAt,
  });

  factory ShipmentHistoryItem.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return ShipmentHistoryItem(
      id: _asInt(json['id']),
      publicCode: json['public_code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      estimatedFare: _asInt(json['estimated_fare']),
      sizeLabel: json['size_label']?.toString() ?? '',
      quantity: _asInt(json['quantity']),
      fragile: json['fragile'] == true,
      stopsCount: json['stops_count']?.toString() ?? '',
      pickup: json['pickup']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

@immutable
class ShipmentHistoryPage {
  final int count;
  final List<ShipmentHistoryItem> results;

  const ShipmentHistoryPage({
    required this.count,
    required this.results,
  });

  factory ShipmentHistoryPage.fromJson(Map<String, dynamic> json) {
    final list = (json['results'] as List? ?? const [])
        .map((e) => ShipmentHistoryItem.fromJson(
      Map<String, dynamic>.from(e as Map),
    ))
        .toList();

    int _asInt(dynamic v) {
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return ShipmentHistoryPage(
      count: _asInt(json['count']),
      results: list,
    );
  }
}
