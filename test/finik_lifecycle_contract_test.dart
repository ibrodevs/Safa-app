import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Finik route closes outside SDK descendant callbacks', () {
    final screen = File(
      'lib/features/main_module/payments/view/finik_payment_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('void _finishPayment(bool paid)'));
    expect(screen, contains('addPostFrameCallback'));
    expect(screen, contains('onBackPressed: _handleFinikBack'));
    expect(screen, contains('onPayment: _handleFinikPayment'));
    expect(screen, isNot(contains("if (status == 'FAILED')")));
  });

  test('flow status rebuilds only the overlay, not the Finik SDK subtree', () {
    final screen = File(
      'lib/features/main_module/payments/view/finik_payment_screen.dart',
    ).readAsStringSync();

    expect(
      RegExp(
        r'context\.watch<FinikPaymentFlowProvider>\(\)',
      ).allMatches(screen),
      hasLength(1),
    );
    expect(screen, contains('Timer? _successCloseTimer'));
    expect(screen, isNot(contains('Timer(const Duration(milliseconds: 1400)')));
  });

  test('Amanat keeps its sheet mounted while the Finik route is open', () {
    final amanat = File(
      'lib/features/main_module/amanat/amanat_screen.dart',
    ).readAsStringSync();
    final pushIndex = amanat.indexOf("pushNamed<bool>('finik_pay')");
    final popIndex = amanat.indexOf(
      'Navigator.of(sheetContext).pop()',
      pushIndex,
    );

    expect(pushIndex, greaterThanOrEqualTo(0));
    expect(popIndex, greaterThan(pushIndex));
  });
}
