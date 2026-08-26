import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native Yandex map forwards taps to the point picker', () {
    final adapter = File(
      'lib/core/map/safa_yandex_map.dart',
    ).readAsStringSync();
    final picker = File(
      'lib/features/main_module/map/view/components/map_picker_screen.dart',
    ).readAsStringSync();

    expect(adapter, contains('implements ymk.MapInputListener'));
    expect(adapter, contains('map.removeInputListener(_mapTapListener)'));
    expect(adapter, contains('..addInputListener(_mapTapListener)'));
    // Тап по карте ведёт в _moveTo и сразу запрашивает адрес именно для
    // тапнутых координат, не дожидаясь конца анимации камеры.
    expect(
      picker,
      contains('_moveTo(point, zoom: _zoom, immediateReverse: true)'),
    );
    expect(picker, contains('final point = _addressPoint ?? _center;'));
  });

  test('picker cannot confirm coordinates while address is unresolved', () {
    final picker = File(
      'lib/features/main_module/map/view/components/map_picker_screen.dart',
    ).readAsStringSync();

    expect(
      picker,
      contains('!hereLoading && hereError == null && hereAddress.isNotEmpty'),
    );
    expect(picker, contains("loadingLabel: 'Определяем адрес…'"));
  });

  test('zoom does not recreate all native map objects every frame', () {
    final adapter = File(
      'lib/core/map/safa_yandex_map.dart',
    ).readAsStringSync();

    expect(adapter, contains('if (finished) _updateVisibleBounds();'));
    expect(adapter, contains('_polylineSignature'));
    expect(adapter, contains('_polygonSignature'));
    expect(adapter, isNot(contains('Object.hashAll(widget.polylines),')));
  });
}
