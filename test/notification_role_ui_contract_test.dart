import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nearby-order setting is carrier-only and technical tags are hidden', () {
    final screen = File(
      'lib/features/main_module/profile/view/components/profile_notifications_screen.dart',
    ).readAsStringSync();
    final router = File('lib/core/router/app_router.dart').readAsStringSync();

    expect(screen, contains('if (widget.isCarrier)'));
    expect(screen, contains("this.role = 'client'"));
    expect(screen, isNot(contains('class _Tag extends StatelessWidget')));
    expect(screen, isNot(contains('Источник: сервер')));
    expect(router, contains("queryParameters['role'] ?? 'client'"));
  });
}
