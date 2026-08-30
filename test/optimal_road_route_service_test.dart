import 'package:dogo/core/map/optimal_road_route_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('optimal route chooses shortest distance when duration is equal', () {
    final best = OptimalRoadRouteService.selectBestRoute([
      {'duration': 600, 'distance': 7000, 'geometry': const {}},
      {'duration': 600, 'distance': 5200, 'geometry': const {}},
      {'duration': 750, 'distance': 4000, 'geometry': const {}},
    ]);

    expect(best?['duration'], 600);
    expect(best?['distance'], 5200);
  });

  test('optimal route prioritizes travel time before distance', () {
    final best = OptimalRoadRouteService.selectBestRoute([
      {'duration': 900, 'distance': 4000, 'geometry': const {}},
      {'duration': 540, 'distance': 5000, 'geometry': const {}},
    ]);

    expect(best?['duration'], 540);
  });
}
