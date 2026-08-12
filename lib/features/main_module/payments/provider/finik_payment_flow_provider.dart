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

  void startPollingPaid({
    Duration interval = const Duration(seconds: 2),
    int maxSeconds = 40,
  }) {
    if (!hasPaymentTarget) return;

    _pollTimer?.cancel();
    _pollTicks = 0;

    status = FinikFlowStatus.polling;
    notifyListeners();

    final maxTicks = (maxSeconds * 1000) ~/ interval.inMilliseconds;

    _pollTimer = Timer.periodic(interval, (t) async {
      if (_pollInFlight) return;
      _pollInFlight = true;
      _pollTicks++;

      try {
        final paid = shipmentId != null
            ? await _shipmentsRepo.isShipmentPaid(shipmentId!)
            : await _paymentsRepo.isAmanatDonationPaid(
                campaignId: amanatCampaignId!,
                donationId: amanatDonationId!,
              );
        if (paid) {
          t.cancel();
          status = FinikFlowStatus.succeeded;
          notifyListeners();
          return;
        }

        if (_pollTicks >= maxTicks) {
          t.cancel();
          status = FinikFlowStatus.failed;
          errorText =
              'Оплата не подтвердилась. Попробуйте обновить статус позже.';
          notifyListeners();
        }
      } catch (e) {
        if (_pollTicks >= maxTicks) {
          t.cancel();
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
    });
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
    _pollTimer?.cancel();
    super.dispose();
  }
}
