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

  /// Достаёт человекочитаемый текст из ответа DRF.
  ///
  /// Ошибки валидации приходят вложенными:
  /// `{"stops": {"0": ["Точка должна быть внутри базара"]}}`.
  /// Раньше в исключение уходил `toString()` всей карты, и пользователь видел
  /// только «Не удалось создать заказ» — без причины.
  static String? _detailMessage(dynamic data, {int depth = 0}) {
    if (depth > 4) return null;

    if (data is String) {
      final value = data.trim();
      if (value.isEmpty || value.startsWith('<')) return null;
      // Технические коды вроде only_for_client показывать нет смысла.
      if (!value.contains(' ')) return null;
      return value;
    }
    if (data is List) {
      for (final item in data) {
        final message = _detailMessage(item, depth: depth + 1);
        if (message != null) return message;
      }
      return null;
    }
    if (data is Map) {
      for (final key in const ['detail', 'error', 'message']) {
        if (data.containsKey(key)) {
          final message = _detailMessage(data[key], depth: depth + 1);
          if (message != null) return message;
        }
      }
      for (final value in data.values) {
        final message = _detailMessage(value, depth: depth + 1);
        if (message != null) return message;
      }
    }
    return null;
  }

  static ApiException _asApiException(DioException error, String fallback) {
    final status = error.response?.statusCode;
    final detail = _detailMessage(error.response?.data);
    return ApiException(detail ?? fallback, statusCode: status);
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
      throw _asApiException(e, 'Не удалось создать доставку');
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
      throw _asApiException(e, 'Не удалось проверить оплату');
    }
  }
}

class ShipmentsListItemDto {
  final int id;
  final String status;
  final List<DeliveryPoint> stops;
  final bool isPaid;
  final int fare;
  final String? carrierFirstName;
  final String? carrierPhone;
  final String? carrierAvatarUrl;
  final String? carrierSpecialistType;

  const ShipmentsListItemDto({
    required this.id,
    required this.status,
    required this.stops,
    this.isPaid = false,
    this.fare = 0,
    this.carrierFirstName,
    this.carrierPhone,
    this.carrierAvatarUrl,
    this.carrierSpecialistType,
  });

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
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
        final district = m['district']?.toString();
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
        if (district != null && district.trim().isNotEmpty) {
          subtitleParts.add('Район: ${district.trim()}');
        }
        if (passage != null && passage.trim().isNotEmpty) {
          subtitleParts.add('Проход: ${passage.trim()}');
        }
        if (container != null && container.trim().isNotEmpty) {
          subtitleParts.add('Контейнер: ${container.trim()}');
        }

        stops.add(
          DeliveryPoint(
            title: bazar?.trim().isNotEmpty == true
                ? 'Базар: ${bazar!.trim()}'
                : (title.isNotEmpty ? title : 'Точка'),
            subtitle: subtitleParts.join(' · '),
            lat: lat,
            lon: lon,
            bazar: bazar ?? '',
            district: district ?? '',
            passage: passage ?? '',
            container: container ?? '',
            q: '',
          ),
        );
      }
    }

    final finalFare = _toInt(j['final_fare']);
    final estimatedFare = _toInt(j['estimated_fare']);
    final paymentDueAmount = _toInt(j['payment_due_amount']);

    return ShipmentsListItemDto(
      id: _toInt(j['id']),
      status: (j['status'] ?? '').toString(),
      stops: stops,
      isPaid: j['is_paid'] == true,
      fare: paymentDueAmount > 0
          ? paymentDueAmount
          : (finalFare > 0 ? finalFare : estimatedFare),
      carrierFirstName: j['carrier_first_name']?.toString(),
      carrierPhone: j['carrier_phone']?.toString(),
      carrierAvatarUrl: j['carrier_avatar_url']?.toString(),
      carrierSpecialistType: j['carrier_specialist_type']?.toString(),
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
          return dto;
        }
      }

      return null;
    } on DioException catch (e) {
      throw ShipmentsRepository._asApiException(
        e,
        'Не удалось загрузить доставки',
      );
    }
  }
}
