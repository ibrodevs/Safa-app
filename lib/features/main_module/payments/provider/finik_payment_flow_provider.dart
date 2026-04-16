import 'dart:async';
import 'package:flutter/foundation.dart';
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
  })  : _shipmentsRepo = shipmentsRepo,
        _paymentsRepo = paymentsRepo;

  final ShipmentsRepository _shipmentsRepo;
  final FinikPaymentsRepository _paymentsRepo;

  FinikFlowStatus status = FinikFlowStatus.initial;
  String? errorText;

  int? shipmentId;
  FinikPayInitResponse? init;

  Timer? _pollTimer;
  int _pollTicks = 0;

  void reset() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollTicks = 0;
    status = FinikFlowStatus.initial;
    errorText = null;
    shipmentId = null;
    init = null;
    notifyListeners();
  }

  Future<void> startExistingShipmentPayment(int id) async {
    if (status != FinikFlowStatus.initial && status != FinikFlowStatus.failed) return;

    try {
      shipmentId = id;
      status = FinikFlowStatus.waiting;
      errorText = null;
      notifyListeners();

      init = await _paymentsRepo.startFinikPayment(id);

      status = FinikFlowStatus.awaitingFinikUi;
      notifyListeners();
    } catch (e) {
      status = FinikFlowStatus.failed;
      errorText = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> createShipmentAndStartPayment({
    required String title,
    required String description,
    required List<Map<String, dynamic>> stops,
  }) async {
    if (status != FinikFlowStatus.initial) return;

    try { 
      status = FinikFlowStatus.waiting;
      errorText = null;
      notifyListeners();

      final id = await _shipmentsRepo.createShipment(
        title: title,
        description: description,
        stops: stops,
      );
      shipmentId = id;

      status = FinikFlowStatus.waiting;
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
