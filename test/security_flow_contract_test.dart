import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('account deletion uses the backend POST contract', () {
    final source = File('lib/data/network/api_service.dart').readAsStringSync();
    expect(source, contains("_dio.post('users/delete-account/')"));
    expect(source, isNot(contains("_dio.delete('users/delete-account/')")));
  });

  test('carrier KYC requests include a secure enrollment token', () {
    final source = File('lib/data/network/api_service.dart').readAsStringSync();
    expect(source, contains("'kyc_token': kycToken"));
    expect(source, contains('getKycEnrollmentToken'));
  });
}
