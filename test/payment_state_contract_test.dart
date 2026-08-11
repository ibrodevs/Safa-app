import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new shipment is never marked paid on the client', () {
    final source = File(
      'lib/features/main_module/map/view/map_screen.dart',
    ).readAsStringSync();

    expect(source, contains('_isPaid = false;'));
    expect(
      source,
      isNot(contains('До назначения исполнителя щит оплаты не нужен')),
    );
  });
}
