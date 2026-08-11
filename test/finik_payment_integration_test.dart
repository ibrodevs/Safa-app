import 'package:dogo/features/main_module/payments/data/model/finik_pay_init_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Finik init response carries server-owned payment configuration', () {
    final response = FinikPayInitResponse.fromJson({
      'paymentId': 'payment-123',
      'finikRequestId': 'request-123',
      'callbackUrl': 'https://api.example.com/api/payments/finik/callback/',
      'amount': 450,
      'currency': 'KGS',
      'accountId': 'account-123',
      'requiredFields': {
        'paymentId': 'payment-123',
        'finikRequestId': 'request-123',
        'shipmentId': '42',
      },
    });

    expect(response.paymentId, 'payment-123');
    expect(response.accountId, 'account-123');
    expect(response.amount, 450);
    expect(response.requiredFields['finikRequestId'], 'request-123');
  });

  test('Finik init response accepts snake_case backend aliases', () {
    final response = FinikPayInitResponse.fromJson({
      'payment_id': 'payment-123',
      'finik_request_id': 'request-123',
      'callback_url': 'https://api.example.com/callback/',
      'account_id': 'account-123',
      'required_fields': const <String, dynamic>{},
      'amount': 1,
    });

    expect(response.paymentId, 'payment-123');
    expect(response.finikRequestId, 'request-123');
    expect(response.accountId, 'account-123');
  });
}
