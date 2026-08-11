import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'carrier sees an explicit waiting-for-payment state after completion',
    () {
      final source = File(
        'lib/features/carrier_module/home/carrier_home_screen.dart',
      ).readAsStringSync();

      expect(
        source,
        contains('_activeStatus == ShipmentStatus.awaitingPayment'),
      );
      expect(source, contains('_AwaitingPaymentSheet('));
      expect(source, contains('Ожидаем оплату клиента'));
      expect(source, contains('Работа выполнена. Ожидаем оплату клиента.'));
      expect(source, contains('_showWelcome = false;'));
    },
  );
}
