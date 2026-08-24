import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('specialist registration has no document or approval bypass', () {
    final registration = File(
      'lib/features/auth_module/register/view/carrier_register_screen.dart',
    ).readAsStringSync();

    expect(registration, isNot(contains('_bypassDocumentsPhone')));
    expect(registration, contains('Загрузите обе стороны документа'));
    expect(registration, contains("context.push('/register/confirm')"));
  });

  test('waiting specialist registers for approval push notifications', () {
    final waiting = File(
      'lib/features/auth_module/register/view/components/selfie_waiting_screen.dart',
    ).readAsStringSync();
    final push = File(
      'lib/data/notifications/service/push_service.dart',
    ).readAsStringSync();
    final api = File('lib/data/network/api_service.dart').readAsStringSync();
    final router = File(
      'lib/data/notifications/service/notification_router.dart',
    ).readAsStringSync();

    expect(waiting, contains('registerPendingCarrier()'));
    expect(api, contains("'fcm/register-kyc/'"));
    expect(push, contains("kind == 'carrier_pending'"));
    expect(router, contains("type == 'kyc_status'"));
    expect(router, contains("go('/selfie-waiting')"));
  });
}
