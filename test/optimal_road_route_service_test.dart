import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('route service uses Yandex pedestrian routing only', () {
    final source = File(
      'lib/core/map/yandex_pedestrian_route_service.dart',
    ).readAsStringSync();

    expect(source, contains('createPedestrianRouter()'));
    expect(source, contains('RequestPointType.Waypoint'));
    expect(source, isNot(contains('driving')));
    expect(source, isNot(contains('route/v1/')));
  });
}
