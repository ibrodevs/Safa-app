import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Amanat uses centered header, usable back button and details action', () {
    final source = File(
      'lib/features/main_module/amanat/amanat_screen.dart',
    ).readAsStringSync();

    expect(source, contains("const String _amanatHomeTitle = 'Аманат';"));
    expect(
      source,
      contains('BoxConstraints.tightFor(width: 44, height: 44)'),
    );
    expect(source, contains('textAlign: TextAlign.center'));
    expect(source, contains("tooltip: 'Назад'"));
    expect(source, contains("label: const Text('Подробнее')"));
    expect(source, contains('maxLines: compactTitle ? 1 : 2'));
  });
}
