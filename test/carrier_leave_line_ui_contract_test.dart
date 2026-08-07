import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('carrier leave-line action resets the carrier home screen', () {
    final leaveLineSource = File(
      'lib/features/carrier_module/home/view/comp/empty_orders_screen.dart',
    ).readAsStringSync();
    final routerSource = File(
      'lib/core/router/app_router.dart',
    ).readAsStringSync();

    expect(leaveLineSource, contains('Выйти с линии'));
    expect(leaveLineSource, contains('Вы перестанете искать новые заказы'));
    expect(leaveLineSource, contains('DateTime.now().microsecondsSinceEpoch'));
    expect(
      leaveLineSource,
      contains("context.go('/home-carrier?line=off&reset=\$resetToken')"),
    );

    // Выход с линии не ждёт backend-запрос и не должен зависать в loading.
    expect(leaveLineSource, isNot(contains('_leavingLine')));
    expect(leaveLineSource, isNot(contains('CircularProgressIndicator')));

    // Изменение reset token должно создавать новый CarrierHomeScreen. Его dispose
    // останавливает существующий nearby polling timer.
    expect(routerSource, contains("ValueKey('carrier-home-\${state.uri}')"));
  });
}
