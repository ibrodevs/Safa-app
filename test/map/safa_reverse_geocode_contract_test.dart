import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('map reverse geocoding queries backend first with client fallback', () {
    final source = File(
      'lib/features/main_module/map/data/repo/delivery_geo_repository.dart',
    ).readAsStringSync();

    final backendIndex = source.indexOf("'delivery/geo/reverse/'");
    final fallbackOsmIndex = source.indexOf('_osm.reverseRaw');

    expect(backendIndex, greaterThanOrEqualTo(0));
    expect(fallbackOsmIndex, greaterThanOrEqualTo(0));
    expect(backendIndex, lessThan(fallbackOsmIndex));
    expect(source, contains("json['address']"));
  });
}
