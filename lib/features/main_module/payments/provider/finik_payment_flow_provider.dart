import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/friendly_error.dart';
import '../../../../core/config/finik_config.dart';
import '../data/model/finik_pay_init_response.dart';
import '../data/repo/finik_payments_repository.dart';
import '../data/repo/shipments_repository.dart';

enum FinikFlowStatus {
  initial,
  awaitingFinikUi,
  polling,
  waiting,
  succeeded,
  failed,
}

final class FinikPaymentFlowProvider extends ChangeNotifier {
  FinikPaymentFlowProvider({
    required ShipmentsRepository shipmentsRepo,
    required FinikPaymentsRepository paymentsRepo,
  }) : _shipmentsRepo = shipmentsRepo,
       _paymentsRepo = paymentsRepo;

  final ShipmentsRepository _shipmentsRepo;
  final FinikPaymentsRepository _paymentsRepo;

  FinikFlowStatus status = FinikFlowStatus.initial;
  String? errorText;

  int? shipmentId;
  int? amanatCampaignId;
  int? amanatDonationId;
  FinikPayInitResponse? init;
  String? finikItemId;
  String? finikTransactionId;

  bool get hasPaymentTarget => shipmentId != null || amanatDonationId != null;
  String get paymentDescription =>
      shipmentId != null ? 'Заказ #$shipmentId' : 'Пожертвование Safa Amanat';
  String get successMessage => amanatDonationId != null
      ? 'Пожертвование успешно оплачено'
      : 'Заказ успешно оплачен';

  Timer? _pollTimer;
  int _pollTicks = 0;
  bool _pollInFlight = false;

  void reset() {
    _qrBackgroundTimer?.cancel();
    _qrBackgroundTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollTicks = 0;
    _pollInFlight = false;
    status = FinikFlowStatus.initial;
    errorText = null;
    shipmentId = null;
    amanatCampaignId = null;
    amanatDonationId = null;
    init = null;
    finikItemId = null;
    finikTransactionId = null;
    notifyListeners();
  }

  Future<void> startExistingShipmentPayment(int id) async {
    if (status != FinikFlowStatus.initial && status != FinikFlowStatus.failed) {
      return;
    }

    try {
      shipmentId = id;
      status = FinikFlowStatus.waiting;
      errorText = null;
      notifyListeners();

      await _paymentsRepo.assertServerReady(
        expectedBeta: FinikConfig.isBeta,
        appApiKey: FinikConfig.apiKey,
      );
      init = await _paymentsRepo.startFinikPayment(id);

      status = FinikFlowStatus.awaitingFinikUi;
      notifyListeners();
    } catch (e) {
      status = FinikFlowStatus.failed;
      errorText = friendlyErrorMessage(e, fallback: 'Не удалось начать оплату');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> startAmanatDonationPayment({
    required int campaignId,
    required int amount,
    required bool isAnonymous,
  }) async {
    if (status != FinikFlowStatus.initial && status != FinikFlowStatus.failed) {
      return;
    }
    try {
      status = FinikFlowStatus.waiting;
      errorText = null;
      notifyListeners();
      await _paymentsRepo.assertServerReady(
        expectedBeta: FinikConfig.isBeta,
        appApiKey: FinikConfig.apiKey,
      );
      final donation = await _paymentsRepo.startAmanatDonation(
        campaignId: campaignId,
        amount: amount,
        isAnonymous: isAnonymous,
      );
      amanatCampaignId = campaignId;
      amanatDonationId = donation.donationId;
      init = donation.payment;
      status = FinikFlowStatus.awaitingFinikUi;
      notifyListeners();
    } catch (e) {
      status = FinikFlowStatus.failed;
      errorText = friendlyErrorMessage(
        e,
        fallback: 'Не удалось начать пожертвование через Finik',
      );
      notifyListeners();
      rethrow;
    }
  }

  Timer? _qrBackgroundTimer;

  void recordCreatedItem(Map<String, dynamic>? data) {
    if (data == null) return;
    final id = data['id']?.toString();
    if (id == null || id.isEmpty) return;
    finikItemId = id;
    final payment = init;
    if (payment != null) {
      unawaited(
        _paymentsRepo.reconcileShipmentPayment(
          paymentId: payment.paymentId,
          itemId: id,
        ),
      );
      _startBackgroundQrPolling();
    }
  }

  void _startBackgroundQrPolling() {
    _qrBackgroundTimer?.cancel();
    _qrBackgroundTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (status != FinikFlowStatus.awaitingFinikUi) {
        timer.cancel();
        return;
      }
      try {
        var paid = false;
        final payment = init;
        if (payment != null) {
          paid = await _paymentsRepo.reconcileShipmentPayment(
            paymentId: payment.paymentId,
            itemId: finikItemId,
            transactionId: finikTransactionId,
          );
        }
        if (shipmentId != null) {
          paid = paid || await _shipmentsRepo.isShipmentPaid(shipmentId!);
        } else if (amanatCampaignId != null && amanatDonationId != null) {
          paid = paid ||
              await _paymentsRepo.isAmanatDonationPaid(
                campaignId: amanatCampaignId!,
                donationId: amanatDonationId!,
              );
        }
        if (paid) {
          timer.cancel();
          _pollTimer?.cancel();
          status = FinikFlowStatus.succeeded;
          notifyListeners();
        }
      } catch (_) {}
    });
  }

  void handlePaymentResult(Map<String, dynamic>? data) {
    if (data == null) return;
    final item = data['item'];
    if (item is Map) {
      final id = item['id']?.toString();
      if (id != null && id.isNotEmpty) finikItemId = id;
    }
    final transactionId = data['transactionId']?.toString();
    if (transactionId != null && transactionId.isNotEmpty) {
      finikTransactionId = transactionId;
    }
    final result = (data['status'] ?? '').toString().toUpperCase();
    if (result == 'SUCCEEDED') {
      startPollingPaid();
    } else if (result == 'FAILED') {
      markFailed('Платёж отклонён');
    }
  }

  void startPollingPaid({
    Duration interval = const Duration(milliseconds: 1500),
    int maxSeconds = 60,
  }) {
    if (!hasPaymentTarget) return;

    _pollTimer?.cancel();
    _pollTicks = 0;

    status = FinikFlowStatus.polling;
    notifyListeners();

    final maxTicks = (maxSeconds * 1000) ~/ interval.inMilliseconds;

    unawaited(_pollPaidOnce(maxTicks));
    _pollTimer = Timer.periodic(interval, (_) => _pollPaidOnce(maxTicks));
  }

  Future<void> _pollPaidOnce(int maxTicks) async {
    if (_pollInFlight || status != FinikFlowStatus.polling) return;
    _pollInFlight = true;
    _pollTicks++;
    try {
      var paid = false;
      final payment = init;
      if (payment != null) {
        paid = await _paymentsRepo.reconcileShipmentPayment(
          paymentId: payment.paymentId,
          itemId: finikItemId,
          transactionId: finikTransactionId,
        );
      }
      if (shipmentId != null) {
        paid = paid || await _shipmentsRepo.isShipmentPaid(shipmentId!);
      } else if (amanatCampaignId != null && amanatDonationId != null) {
        paid = paid ||
            await _paymentsRepo.isAmanatDonationPaid(
              campaignId: amanatCampaignId!,
              donationId: amanatDonationId!,
            );
      }
      if (paid) {
        _pollTimer?.cancel();
        status = FinikFlowStatus.succeeded;
        notifyListeners();
      } else if (_pollTicks >= maxTicks) {
        _pollTimer?.cancel();
        status = FinikFlowStatus.failed;
        errorText = 'Оплата пока не подтверждена. Проверьте статус ещё раз.';
        notifyListeners();
      }
    } catch (e) {
      if (_pollTicks >= maxTicks) {
        _pollTimer?.cancel();
        status = FinikFlowStatus.failed;
        errorText = friendlyErrorMessage(
          e,
          fallback: 'Не удалось проверить статус оплаты',
        );
        notifyListeners();
      }
    } finally {
      _pollInFlight = false;
    }
  }

  void markFailed(String message) {
    _pollTimer?.cancel();
    status = FinikFlowStatus.failed;
    errorText = message;
    notifyListeners();
  }

  void markSucceeded() {
    _pollTimer?.cancel();
    status = FinikFlowStatus.succeeded;
    notifyListeners();
  }

  @override
  void dispose() {
    _qrBackgroundTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}
