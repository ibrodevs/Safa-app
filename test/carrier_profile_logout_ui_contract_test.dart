import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('carrier profile shows logout button', () {
    final profileSource = File(
      'lib/features/carrier_module/profile/view/carrier_profile_screen.dart',
    ).readAsStringSync();
    final logoutSource = File(
      'lib/features/carrier_module/profile/widgets/carrier_logout_button.dart',
    ).readAsStringSync();

    expect(profileSource, contains('const CarrierLogoutButton()'));
    expect(logoutSource, contains("label: 'Выйти из аккаунта'"));
    expect(logoutSource, contains('LogoutService().logout()'));
  });
}
