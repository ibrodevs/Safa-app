import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('logout service clears carrier session state', () {
    final source = File('lib/data/services/logout_service.dart').readAsStringSync();

    expect(source, contains('resetAll()'));
    expect(source, contains('setBearer(null)'));
    expect(source, contains("setBool('is_logged_in', false)"));
    expect(source, contains("remove('user_role')"));
    expect(source, contains("remove('carrier_pending')"));
  });
}
