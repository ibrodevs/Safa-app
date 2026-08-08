import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('specialist incoming order shows service, price and compact stops', () {
    final source = File(
      'lib/features/carrier_module/home/carrier_home_screen.dart',
    ).readAsStringSync();

    expect(source, contains('shipment.serviceLabel'));
    expect(source, contains('shipment.displayFare'));
    expect(source, contains('shipment.stops[i].compactAddress'));
    expect(source, contains("j['final_fare']"));
  });
}
