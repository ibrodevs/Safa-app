import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('carrier waiting screen exposes leave-line action', () {
    final source = File(
      'lib/features/carrier_module/home/view/comp/empty_orders_screen.dart',
    ).readAsStringSync();

    expect(source, contains('Выйти с линии'));
    expect(source, contains("context.go('/home-carrier?line=off')"));
    expect(source, contains('Вы перестанете искать новые заказы'));
  });
}
