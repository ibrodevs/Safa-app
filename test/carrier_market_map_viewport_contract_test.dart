import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('carrier does not request or render backend-authored map layers', () {
    final source = File(
      'lib/features/carrier_module/home/carrier_home_screen.dart',
    ).readAsStringSync();
    final mapConfig = File(
      'lib/core/map/safa_yandex_map.dart',
    ).readAsStringSync();

    expect(source, contains('_refreshMarketMapForViewport'));
    expect(
      source,
      contains(
        'if (!SafaMobileMapFeatures.backendDrawingLayersEnabled) return;',
      ),
    );
    expect(mapConfig, contains('backendDrawingLayersEnabled = false'));
  });
}
