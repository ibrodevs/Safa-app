import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../type_cargo/data/model/finik_pay_init_response.dart';
import '../data/repo/finik_payments_repository.dart';
import '../data/repo/shipments_repository.dart';

enum FinikFlowStatus {
  idle,
  creatingShipment,
  startingPayment,
  awaitingFinikUi,
  polling,
  succeeded,
  failed,
}

final class FinikPaymentFlowProvider extends ChangeNotifier {
  FinikPaymentFlowProvider({
    required ShipmentsRepository shipmentsRepo,
    required FinikPaymentsRepository paymentsRepo,
  })  : _shipmentsRepo = shipmentsRepo,
        _paymentsRepo = paymentsRepo;

  final ShipmentsRepository _shipmentsRepo;
  final FinikPaymentsRepository _paymentsRepo;

  FinikFlowStatus status = FinikFlowStatus.idle;
  String? errorText;

  int? shipmentId;
  FinikPayInitResponse? init;

  Timer? _pollTimer;
  int _pollTicks = 0;

  void reset() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollTicks = 0;
    status = FinikFlowStatus.idle;
    errorText = null;
    shipmentId = null;
    init = null;
    notifyListeners();
  }

  Future<void> createShipmentAndStartPayment({
    required String title,
    required int segmentId,
    required int quantity,
    required List<Map<String, dynamic>> stops,
  }) async {
    if (status != FinikFlowStatus.idle) return;

    try {
      status = FinikFlowStatus.creatingShipment;
      errorText = null;
      notifyListeners();

      final id = await _shipmentsRepo.createShipment(
        title: title,
        segment: segmentId,
        quantity: quantity,
        stops: stops,
      );
      shipmentId = id;

      status = FinikFlowStatus.startingPayment;
      notifyListeners();

      init = await _paymentsRepo.startFinikPayment(id);

      status = FinikFlowStatus.awaitingFinikUi;
      notifyListeners();
    } catch (e) {
      status = FinikFlowStatus.failed;
      errorText = e.toString();
      notifyListeners();
    }
  }

  void startPollingPaid({Duration interval = const Duration(seconds: 2), int maxSeconds = 40}) {
    final id = shipmentId;
    if (id == null) return;

    _pollTimer?.cancel();
    _pollTicks = 0;

    status = FinikFlowStatus.polling;
    notifyListeners();

    final maxTicks = (maxSeconds * 1000) ~/ interval.inMilliseconds;

    _pollTimer = Timer.periodic(interval, (t) async {
      _pollTicks++;

      try {
        final paid = await _shipmentsRepo.isShipmentPaid(id);
        if (paid) {
          t.cancel();
          status = FinikFlowStatus.succeeded;
          notifyListeners();
          return;
        }

        if (_pollTicks >= maxTicks) {
          t.cancel();
          status = FinikFlowStatus.failed;
          errorText = 'Оплата не подтвердилась. Попробуйте обновить статус позже.';
          notifyListeners();
        }
      } catch (e) {
        if (_pollTicks >= maxTicks) {
          t.cancel();
          status = FinikFlowStatus.failed;
          errorText = e.toString();
          notifyListeners();
        }
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
