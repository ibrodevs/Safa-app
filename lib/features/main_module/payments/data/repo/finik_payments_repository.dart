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
      final purposes =
          (config['paymentPurposes'] as List?)
              ?.map((value) => value.toString())
              .toSet() ??
          const <String>{};
      if (version < 3 || !purposes.containsAll(const {'shipment', 'amanat'})) {
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

  Future<FinikDonationInit> startAmanatDonation({
    required int campaignId,
    required int amount,
    required bool isAnonymous,
  }) async {
    try {
      final resp = await _api.dio.post(
        'delivery/amanat/campaigns/$campaignId/donate/',
        data: {'amount': amount, 'is_anonymous': isAnonymous},
      );
      final map = _asMap(resp.data);
      final parsed = FinikPayInitResponse.fromJson(map);
      final donationId = (map['donationId'] as num?)?.toInt() ?? 0;
      _validateInit(parsed);
      if (donationId <= 0 || parsed.requiredFields['paymentKind'] != 'amanat') {
        throw ApiException('Некорректный ответ оплаты пожертвования');
      }
      return FinikDonationInit(donationId: donationId, payment: parsed);
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?.toString() ??
            'Не удалось начать пожертвование через Finik',
      );
    }
  }

  Future<bool> isAmanatDonationPaid({
    required int campaignId,
    required int donationId,
  }) async {
    try {
      final resp = await _api.dio.get(
        'delivery/amanat/campaigns/$campaignId/donations/$donationId/',
      );
      return _asMap(resp.data)['status'] == 'paid';
    } on DioException catch (e) {
      throw ApiException(
        e.response?.data?.toString() ?? 'Не удалось проверить пожертвование',
      );
    }
  }

  Future<bool> reconcileShipmentPayment({
    required String paymentId,
    String? itemId,
    String? transactionId,
  }) async {
    try {
      final resp = await _api.dio.post(
        'payments/finik/reconcile/',
        data: {
          'paymentId': paymentId,
          if (itemId != null && itemId.isNotEmpty) 'itemId': itemId,
          if (transactionId != null && transactionId.isNotEmpty)
            'transactionId': transactionId,
        },
      );
      return _asMap(resp.data)['paid'] == true;
    } on DioException catch (e) {
      // 202 means Finik has created the item but has not registered payment yet;
      // 409 can occur while the order is still moving to payment state.
      if (e.response?.statusCode == 202 || e.response?.statusCode == 409) {
        return false;
      }
      throw ApiException(
        e.response?.data?.toString() ?? 'Не удалось подтвердить оплату Finik',
      );
    }
  }

  void _validateInit(FinikPayInitResponse parsed) {
    if (parsed.paymentId.isEmpty ||
        parsed.finikRequestId.isEmpty ||
        parsed.accountId.isEmpty ||
        parsed.amount <= 0 ||
        parsed.requiredFields['paymentId']?.toString() != parsed.paymentId ||
        parsed.requiredFields['finikRequestId']?.toString() !=
            parsed.finikRequestId ||
        !parsed.callbackUrl.startsWith('https://')) {
      throw ApiException('Некорректный ответ Finik');
    }
  }
}
