import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native camera events are throttled but the final event is delivered',
    () {
      final source = File(
        'lib/core/map/safa_yandex_map.dart',
      ).readAsStringSync();

      expect(source, contains('Duration(milliseconds: 80)'));
      expect(source, contains('if (!finished &&'));
      expect(source, contains('if (finished) _updateVisibleBounds();'));
    },
  );

  test('map screens do not rebuild at zoom buckets during gestures', () {
    for (final path in [
      'lib/features/main_module/map/view/map_screen.dart',
      'lib/features/main_module/map/view/components/map_picker_screen.dart',
      'lib/features/carrier_module/home/carrier_home_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('!hasGesture'),
        reason: '$path must defer zoom-dependent rebuilds until camera idle',
      );
    }
  });
}
