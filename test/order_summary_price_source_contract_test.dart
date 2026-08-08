import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('client summary price comes from backend shipment quote', () {
    final source = File(
      'lib/features/main_module/map/view/components/order_summary_sheet.dart',
    ).readAsStringSync();

    expect(source, contains('final quote = await _repo.getQuote('));
    expect(source, contains("quote['estimated_fare']"));
    expect(source, contains('_quoteAmount ='));
  });
}
