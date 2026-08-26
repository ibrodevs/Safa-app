import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('address-only map prefers public address with backend fallback', () {
    final source = File(
      'lib/features/main_module/map/data/repo/delivery_geo_repository.dart',
    ).readAsStringSync();

    final backendIndex = source.indexOf("'delivery/geo/reverse/'");
    final publicAddressIndex = source.indexOf('if (preferPublicAddress)');
    final firstOsmIndex = source.indexOf('_osm.reverseRaw');
    final fallbackOsmIndex = source.lastIndexOf('_osm.reverseRaw');

    expect(backendIndex, greaterThanOrEqualTo(0));
    expect(publicAddressIndex, greaterThanOrEqualTo(0));
    expect(firstOsmIndex, lessThan(backendIndex));
    expect(fallbackOsmIndex, greaterThan(backendIndex));
    expect(source, contains("json['address']"));
  });
}
