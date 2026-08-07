import 'package:flutter/foundation.dart';

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) {
    final s = v.replaceAll(',', '.');
    return double.tryParse(s);
  }
  return null;
}

DateTime _asDateTime(dynamic v) {
  if (v == null) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.tryParse(v.toString())?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

String _asString(dynamic v) => v?.toString() ?? '';

@immutable
class ShipmentStop {
  final int position;
  final String title;
  final double? lat;
  final double? lon;
  final String bazar;
  final String passage;
  final String container;
  final String label;

  const ShipmentStop({
    required this.position,
    required this.title,
    required this.lat,
    required this.lon,
    this.bazar = '',
    this.passage = '',
    this.container = '',
    this.label = '',
  });

  factory ShipmentStop.fromJson(Map<String, dynamic> json) {
    return ShipmentStop(
      position: _asInt(json['position']),
      title: _asString(json['title']),
      lat: _asDouble(json['lat']),
      lon: _asDouble(json['lon']),
      bazar: _asString(json['bazar']),
      passage: _asString(json['passage']),
      container: _asString(json['container']),
      label: _asString(json['label']),
    );
  }

  /// Понятная подпись точки для истории заказа.
  ///
  /// Для контейнерных точек backend уже отдаёт bazar/passage/container.
  /// Старые и произвольные точки продолжают использовать сохранённый title.
  String get displayTitle {
    final bazarValue = bazar.trim();
    final passageValue = passage.trim();
    final containerValue = container.trim();

    final parts = <String>[];
    if (bazarValue.isNotEmpty) parts.add(bazarValue);
    if (passageValue.isNotEmpty) {
      final lower = passageValue.toLowerCase();
      parts.add(lower.contains('проход') ? passageValue : 'Проход $passageValue');
    }
    if (containerValue.isNotEmpty) {
      final lower = containerValue.toLowerCase();
      parts.add(
        lower.contains('контейнер') ? containerValue : 'Контейнер $containerValue',
      );
    }

    if (parts.isNotEmpty) return parts.join(' · ');

    final titleValue = title.trim();
    if (titleValue.isNotEmpty) return titleValue;

    return label.trim();
  }
}

@immutable
class ShipmentDetail {
  final int id;
  final String publicCode;
  final String status;
  final String title;
  final Map<String, dynamic>? segment;
  final String size;
  final int quantity;
  final bool fragile;
  final String description;
  final List<ShipmentStop> stops;
  final String stopsCount;
  final int? estimatedFare;
  final int finalFare;
  final String commission;
  final String courierIncome;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? finishedAt;

  const ShipmentDetail({
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
    required this.paidAt,
    required this.finishedAt,
  });

  factory ShipmentDetail.fromJson(Map<String, dynamic> json) {
    final segmentJson = json['segment'];
    Map<String, dynamic>? segment;
    if (segmentJson is Map) {
      segment = Map<String, dynamic>.from(segmentJson);
    }

    final stopsJson = json['stops'] as List? ?? const [];
    final stops = stopsJson
        .whereType<Map>()
        .map<ShipmentStop>(
          (e) => ShipmentStop.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();

    return ShipmentDetail(
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
      estimatedFare: _asInt(json['estimated_fare']),
      finalFare: _asInt(json['final_fare']),
      commission: _asString(json['commission']),
      courierIncome: _asString(json['courier_income']),
      createdAt: _asDateTime(json['created_at']),
      paidAt: json['paid_at'] != null ? _asDateTime(json['paid_at']) : null,
      finishedAt: json['finished_at'] != null
          ? _asDateTime(json['finished_at'])
          : null,
    );
  }
}
