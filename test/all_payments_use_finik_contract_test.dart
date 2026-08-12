import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every actionable client payment starts the guarded Finik flow', () {
    final shipment = File(
      'lib/features/main_module/map/view/components/shipment_payment_sheet.dart',
    ).readAsStringSync();
    final amanat = File(
      'lib/features/main_module/amanat/amanat_screen.dart',
    ).readAsStringSync();
    final repository = File(
      'lib/features/main_module/payments/data/repo/finik_payments_repository.dart',
    ).readAsStringSync();
    final carrierProfile = File(
      'lib/features/carrier_module/profile/view/carrier_profile_screen.dart',
    ).readAsStringSync();
    final clientProfile = File(
      'lib/features/main_module/profile/view/profile_screen.dart',
    ).readAsStringSync();

    expect(shipment, contains('startExistingShipmentPayment'));
    expect(amanat, contains('startAmanatDonationPayment'));
    expect(repository, contains("campaigns/\$campaignId/donate/"));
    expect(repository, contains('assertServerReady'));
    expect(amanat, isNot(contains('.donate(')));
    expect(carrierProfile, isNot(contains('Пополнить счет')));
    expect(clientProfile, contains('Подтверждённые платежи через Finik'));
    expect(clientProfile, isNot(contains('История пополнений и трат')));
    expect(
      File(
        'lib/features/carrier_module/profile/view/components/balance_top_up_screen.dart',
      ).existsSync(),
      isFalse,
    );
  });
}
