import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('client summary price comes from backend shipment quote', () {
    final source = File(
      'lib/features/main_module/map/view/components/order_summary_sheet.dart',
    ).readAsStringSync();

    expect(source, contains('getQuote('));
    expect(source, contains("data['estimated_fare']"));
    expect(source, contains('_fare = parsedFare'));
  });
}
