import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('carrier map refreshes published Safa map for current viewport', () {
    final source = File(
      'lib/features/carrier_module/home/carrier_home_screen.dart',
    ).readAsStringSync();

    expect(source, contains('_refreshMarketMapForViewport'));
    expect(source, contains('_scheduleMarketMapViewportRefresh'));
    expect(source, contains('onMapReady:'));
    expect(source, contains('maxContainers: 192'));
    expect(source, contains('MarketMapRenderData.fromFeatures'));
  });
}
