import 'package:flutter/foundation.dart';

import 'shipment_detail_model.dart';

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

bool _asBool(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
  return false;
}

DateTime _asDateTime(dynamic v) {
  if (v == null) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.tryParse(v.toString()) ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

@immutable
class ShipmentHistoryItem {
  final int id;
  final String publicCode;
  final String title;
  final int estimatedFare;
  final int quantity;
  final bool fragile;
  final String stopsCount;
  final String status;
  final DateTime createdAt;
  final String? clientFirstName;
  final String? clientPhone;
  final String? clientAvatarUrl;
  final ShipmentReview? review;
  final bool canReview;

  const ShipmentHistoryItem({
    required this.id,
    required this.publicCode,
    required this.title,
    required this.estimatedFare,
    required this.quantity,
    required this.fragile,
    required this.stopsCount,
    required this.status,
    required this.createdAt,
    this.clientFirstName,
    this.clientPhone,
    this.clientAvatarUrl,
    this.review,
    this.canReview = false,
  });

  factory ShipmentHistoryItem.fromJson(Map<String, dynamic> json) {
    return ShipmentHistoryItem(
      id: _asInt(json['id']),
      publicCode: json['public_code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      estimatedFare: _asInt(json['estimated_fare']),
      quantity: _asInt(json['quantity']),
      fragile: _asBool(json['fragile']),
      stopsCount: json['stops_count']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: _asDateTime(json['created_at']),
      clientFirstName: json['client_first_name']?.toString(),
      clientPhone: json['client_phone']?.toString(),
      clientAvatarUrl: json['client_avatar_url']?.toString(),
      review: json['review'] is Map
          ? ShipmentReview.fromJson(
              Map<String, dynamic>.from(json['review'] as Map),
            )
          : null,
      canReview: json['can_review'] == true,
    );
  }
}

@immutable
class ShipmentHistoryPage {
  final int count;
  final List<ShipmentHistoryItem> results;

  const ShipmentHistoryPage({required this.count, required this.results});

  factory ShipmentHistoryPage.fromJson(Map<String, dynamic> json) {
    final list = (json['results'] as List? ?? const [])
        .whereType<Map>()
        .map<ShipmentHistoryItem>(
          (e) => ShipmentHistoryItem.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();

    return ShipmentHistoryPage(count: _asInt(json['count']), results: list);
  }
}
