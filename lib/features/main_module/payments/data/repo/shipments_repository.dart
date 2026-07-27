import 'package:dio/dio.dart';
import '../../../../../data/network/model/api_exeptions_model.dart';
import '../../../../../data/network/api_service.dart';
import '../../../map/data/model/delivery_point_model.dart';

final class ShipmentsRepository {
  ShipmentsRepository({ApiService? api}) : _api = api ?? ApiService.instance;

  final ApiService _api;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Некорректный формат ответа сервера');
  }

  Future<int> createShipment({
    required String title,
    required String description,
    required List<Map<String, dynamic>> stops,
    bool returnToStart = false,
    String serviceType = 'delivery',
  }) async {
    try {
      final resp = await _api.dio.post(
        'delivery/shipments/',
        data: {
          'title': title,
          'service_type': serviceType,
          'description': description,
          'stops': stops,
          'return_to_start': returnToStart,
        },
      );
      final map = _asMap(resp.data);
      final id = map['id'];
      if (id is int) return id;
      final parsed = int.tryParse(id?.toString() ?? '');
      if (parsed == null) throw ApiException('Shipment id не найден в ответе');
      return parsed;
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?.toString() ?? 'Не удалось создать доставку',
      );
    }
  }

  Future<Map<String, dynamic>> getQuote({
    required List<Map<String, dynamic>> stops,
    bool returnToStart = false,
  }) async {
    return _api.getShipmentQuote(stops: stops, returnToStart: returnToStart);
  }

  Future<bool> isShipmentPaid(int shipmentId) async {
    try {
      final resp = await _api.dio.get('delivery/shipments/$shipmentId/');
      final map = _asMap(resp.data);
      final v = map['is_paid'];
      if (v is bool) return v;
      return (v?.toString() ?? '').toLowerCase() == 'true';
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?.toString() ?? 'Не удалось проверить оплату',
      );
    }
  }
}

class ShipmentsListItemDto {
  final int id;
  final String status;
  final List<DeliveryPoint> stops;
  final bool isPaid;
  final int fare;

  const ShipmentsListItemDto({
    required this.id,
    required this.status,
    required this.stops,
    this.isPaid = false,
    this.fare = 0,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  factory ShipmentsListItemDto.fromJson(Map<String, dynamic> j) {
    final rawStops = j['stops'];
    final stops = <DeliveryPoint>[];

    if (rawStops is List) {
      for (final s in rawStops) {
        if (s is! Map) continue;
        final m = Map<String, dynamic>.from(s);

        final title = (m['title'] ?? '').toString();
        final bazar = m['bazar']?.toString();
        final passage = m['passage']?.toString();
        final containerRaw = m['container']?.toString();

        final containerNumber = m['container_number']?.toString();
        final containerLabel = m['container_label']?.toString();

        final container = (containerRaw?.trim().isNotEmpty == true)
            ? containerRaw
            : (containerNumber?.trim().isNotEmpty == true)
            ? containerNumber
            : (containerLabel?.trim().isNotEmpty == true
                  ? containerLabel
                  : null);

        final lat = _toDouble(m['lat']);
        final lon = _toDouble(m['lon']);

        final subtitleParts = <String>[];
        if (bazar != null && bazar.trim().isNotEmpty)
          subtitleParts.add(bazar.trim());
        if (container != null && container.trim().isNotEmpty)
          subtitleParts.add('Контейнер $container');
        if (passage != null && passage.trim().isNotEmpty)
          subtitleParts.add('Проход $passage');

        stops.add(
          DeliveryPoint(
            title: title.isNotEmpty ? title : 'Точка',
            subtitle: subtitleParts.join(' • '),
            lat: lat,
            lon: lon,
            bazar: bazar ?? '',
            passage: passage ?? '',
            container: container ?? '',
            q: '',
          ),
        );
      }
    }

    return ShipmentsListItemDto(
      id: (j['id'] as num).toInt(),
      status: (j['status'] ?? '').toString(),
      stops: stops,
      isPaid: j['is_paid'] == true,
      fare: (() {
        final f = j['final_fare'];
        final e = j['estimated_fare'];
        if (f != null && f is num && f > 0) return f.toInt();
        if (e != null && e is num) return e.toInt();
        return 0;
      })(),
    );
  }
}

extension ShipmentsRepositoryById on ShipmentsRepository {
  Future<ShipmentsListItemDto> getShipmentById(int id) async {
    final resp = await _api.dio.get('delivery/shipments/$id/');
    final map = Map<String, dynamic>.from(resp.data as Map);
    return ShipmentsListItemDto.fromJson(map);
  }
}

extension ShipmentsRepositoryActive on ShipmentsRepository {
  bool _isTerminalStatus(String s) {
    final v = s.toLowerCase();
    return v == 'completed' || v == 'canceled' || v == 'cancelled';
  }

  Future<ShipmentsListItemDto?> getActiveShipment() async {
    try {
      final json = await _api.getShipments(page: 1, pageSize: 50);
      final results = json['results'];

      if (results is! List) return null;

      for (final r in results) {
        if (r is! Map) continue;
        final dto = ShipmentsListItemDto.fromJson(Map<String, dynamic>.from(r));
        if (!_isTerminalStatus(dto.status)) {
          return dto; // первая активная
        }
      }

      return null;
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?.toString() ?? 'Не удалось загрузить доставки',
      );
    }
  }
}
