import 'package:dio/dio.dart';
import '../model/finik_pay_init_response.dart';
import '../../../../../data/network/api_service.dart';
import '../../../../../data/network/model/api_exeptions_model.dart';

final class FinikPaymentsRepository {
  FinikPaymentsRepository({ApiService? api})
    : _api = api ?? ApiService.instance;

  final ApiService _api;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw ApiException('Некорректный формат ответа сервера');
  }

  Future<FinikPayInitResponse> startFinikPayment(int shipmentId) async {
    try {
      final resp = await _api.dio.post(
        'delivery/shipments/$shipmentId/pay/finik/',
      );
      final map = _asMap(resp.data);
      final parsed = FinikPayInitResponse.fromJson(map);

      if (parsed.paymentId.isEmpty || parsed.finikRequestId.isEmpty) {
        throw ApiException('Некорректный ответ /pay/finik/');
      }
      if (parsed.callbackUrl.isEmpty) {
        throw ApiException(
          'callbackUrl пустой. Проверь публичный HTTPS URL на backend.',
        );
      }

      return parsed;
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?.toString() ?? 'Не удалось стартовать оплату Finik',
      );
    }
  }
}
