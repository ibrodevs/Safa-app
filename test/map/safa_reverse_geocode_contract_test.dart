import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reverse geocoding asks Safa backend before OSM fallback', () {
    final source = File(
      'lib/features/main_module/map/data/repo/delivery_geo_repository.dart',
    ).readAsStringSync();

    final backendIndex = source.indexOf("'delivery/geo/reverse/'");
    final osmIndex = source.indexOf('_osm.reverseRaw');

    expect(backendIndex, greaterThanOrEqualTo(0));
    expect(osmIndex, greaterThan(backendIndex));
    expect(source, contains("json['address']"));
  });
}
