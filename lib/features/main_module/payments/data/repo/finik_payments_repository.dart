import 'dart:convert';

import 'package:crypto/crypto.dart';
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

  Future<void> assertServerReady({
    required bool expectedBeta,
    required String appApiKey,
  }) async {
    try {
      final resp = await _api.dio.get('payments/finik/config/');
      final config = _asMap(resp.data);
      final version = (config['paymentFlowVersion'] as num?)?.toInt() ?? 0;
      if (version < 2) {
        throw ApiException(
          'Backend использует старую платёжную логику. Обновите и '
          'перезапустите сервер.',
        );
      }
      if (config['configured'] != true) {
        throw ApiException('Finik не настроен на backend.');
      }
      final serverFingerprint = (config['keyFingerprint'] ?? '').toString();
      final appFingerprint = sha256
          .convert(utf8.encode(appApiKey.trim()))
          .toString()
          .substring(0, 16);
      if (serverFingerprint.isEmpty || serverFingerprint != appFingerprint) {
        throw ApiException(
          'FINIK_API_KEY в приложении и на backend не совпадают.',
        );
      }
      if (config['beta'] != expectedBeta) {
        throw ApiException(
          'Окружения Finik не совпадают: приложение и backend используют '
          'разные режимы beta/production.',
        );
      }
      final callbackUrl = (config['callbackUrl'] ?? '').toString();
      if (!callbackUrl.startsWith('https://')) {
        throw ApiException('На backend не настроен публичный HTTPS callback.');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw ApiException(
          'Backend устарел: endpoint проверки Finik отсутствует. '
          'Выполните git pull и Reload на PythonAnywhere.',
        );
      }
      throw ApiException(
        e.response?.data?.toString() ?? 'Не удалось проверить настройки Finik',
      );
    }
  }

  Future<FinikPayInitResponse> startFinikPayment(int shipmentId) async {
    try {
      final resp = await _api.dio.post(
        'delivery/shipments/$shipmentId/pay/finik/',
      );
      final map = _asMap(resp.data);
      final parsed = FinikPayInitResponse.fromJson(map);

      if (parsed.paymentId.isEmpty ||
          parsed.finikRequestId.isEmpty ||
          parsed.accountId.isEmpty ||
          parsed.amount <= 0 ||
          parsed.requiredFields['paymentId']?.toString() != parsed.paymentId ||
          parsed.requiredFields['finikRequestId']?.toString() !=
              parsed.finikRequestId) {
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
