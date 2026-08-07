import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('carrier shell exposes a real logout action', () {
    final source = File(
      'lib/features/carrier_module/bottom_bar/bottom_tab_bar.dart',
    ).readAsStringSync();

    expect(source, contains("import '../../../data/services/logout_service.dart';"));
    expect(source, contains("title: 'Выйти из аккаунта?'"));
    expect(source, contains("await const LogoutService().logout();"));
    expect(source, contains("context.go('/select_role');"));
    expect(source, contains("'Выйти'"));
  });
}
