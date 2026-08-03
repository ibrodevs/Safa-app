import 'package:flutter_test/flutter_test.dart';
import 'package:dogo/features/main_module/map/data/model/market_map_feature.dart';
import 'package:dogo/features/main_module/map/view/widgets/market_map_layers.dart';

void main() {
  test('parses and renders polygon only at configured zoom', () {
    final feature = MarketMapFeature.fromJson({
      'type': 'Feature',
      'id': 'district-1',
      'properties': {
        'kind': 'district',
        'name': 'Район 1',
        'min_zoom': 14,
        'stroke_color': '#E47F26',
        'fill_color': '#FF8656',
      },
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [74.60, 42.90],
            [74.65, 42.90],
            [74.65, 42.95],
            [74.60, 42.95],
            [74.60, 42.90],
          ],
        ],
      },
    });

    expect(
      MarketMapRenderData.fromFeatures([feature], zoom: 13).polygons,
      isEmpty,
    );
    expect(
      MarketMapRenderData.fromFeatures([feature], zoom: 14).polygons,
      hasLength(1),
    );
  });

  test('container features render as admin-style rectangles with labels', () {
    final feature = MarketMapFeature.fromJson({
      'type': 'Feature',
      'id': 'container-1',
      'properties': {'kind': 'container', 'name': '101', 'min_zoom': 17},
      'geometry': {
        'type': 'Point',
        'coordinates': [74.62, 42.94],
      },
    });

    final data = MarketMapRenderData.fromFeatures([feature], zoom: 18);
    expect(data.polygons, hasLength(1));
    expect(data.polylines, isEmpty);
    expect(data.markers, hasLength(1));
  });
}
