import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('carrier logout returns to role selection', () {
    final shellSource = File(
      'lib/features/carrier_module/bottom_bar/bottom_tab_bar.dart',
    ).readAsStringSync();
    final profileSource = File(
      'lib/features/carrier_module/profile/widgets/carrier_logout_button.dart',
    ).readAsStringSync();

    expect(shellSource, contains("context.go('/select_role')"));
    expect(profileSource, contains("context.go('/select_role')"));
  });
}
