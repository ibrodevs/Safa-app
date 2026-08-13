import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dogo/features/main_module/map/data/model/market_map_feature.dart';
import 'package:dogo/features/main_module/map/view/widgets/market_map_layers.dart';

void main() {
  test('district polygons render from mobile-friendly zoom', () {
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
      MarketMapRenderData.fromFeatures([feature], zoom: 11).polygons,
      isEmpty,
    );
    expect(
      MarketMapRenderData.fromFeatures([feature], zoom: 12).polygons,
      hasLength(1),
    );
  });

  test('container features render rectangles before labels', () {
    final feature = MarketMapFeature.fromJson({
      'type': 'Feature',
      'id': 'container-1',
      'properties': {'kind': 'container', 'name': '101', 'min_zoom': 17},
      'geometry': {
        'type': 'Point',
        'coordinates': [74.62, 42.94],
      },
    });

    final data = MarketMapRenderData.fromFeatures([feature], zoom: 15);
    expect(data.polygons, hasLength(1));
    expect(data.polylines, isEmpty);
    expect(data.markers, isEmpty);
    expect(data.hasRenderedContainers, isTrue);

    final labelledData = MarketMapRenderData.fromFeatures([feature], zoom: 16);
    expect(labelledData.polygons, hasLength(1));
    expect(labelledData.polylines, isEmpty);
    expect(labelledData.markers, hasLength(1));
    expect(labelledData.renderedContainerCount, 1);
  });

  test('published container label stays vertically centered inside marker', () {
    final feature = MarketMapFeature.fromJson({
      'type': 'Feature',
      'id': 'container-centered',
      'properties': {'kind': 'container', 'name': '125', 'min_zoom': 15},
      'geometry': {
        'type': 'Point',
        'coordinates': [74.62, 42.94],
      },
    });

    final marker = MarketMapRenderData.fromFeatures([
      feature,
    ], zoom: 16).markers.single;

    expect(marker.alignment, Alignment.center);
    expect(marker.child, isA<IgnorePointer>());

    final ignorePointer = marker.child as IgnorePointer;
    expect(ignorePointer.child, isA<Center>());

    final center = ignorePointer.child! as Center;
    expect(center.child, isA<Transform>());

    final transform = center.child! as Transform;
    expect(transform.transform.getTranslation().y, 1);
    expect(transform.child, isA<Text>());
  });

  test('container feature rendering is capped near map center', () {
    final features = List.generate(20, (index) {
      return MarketMapFeature.fromJson({
        'type': 'Feature',
        'id': 'container-$index',
        'properties': {'kind': 'container', 'name': '$index', 'min_zoom': 15},
        'geometry': {
          'type': 'Point',
          'coordinates': [74.62 + index * 0.001, 42.94],
        },
      });
    });

    final data = MarketMapRenderData.fromFeatures(
      features,
      zoom: 16,
      center: const LatLng(42.94, 74.62),
      maxContainerFeatures: 5,
    );

    expect(data.polygons, hasLength(5));
    expect(data.markers, hasLength(5));
  });

  test('mobile performance budget caps thousands of published containers', () {
    final features = List.generate(5000, (index) {
      return MarketMapFeature.fromJson({
        'type': 'Feature',
        'id': 'dense-container-$index',
        'properties': {
          'kind': 'container',
          'name': '${index + 1}',
          'min_zoom': 15,
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [
            74.62 + (index % 20) * 0.0001,
            42.94 + (index ~/ 20) * 0.0001,
          ],
        },
      });
    });

    final dataAt16 = MarketMapRenderData.fromFeatures(
      features,
      zoom: 16,
      center: const LatLng(42.94, 74.62),
      maxContainerFeatures: 500,
    );
    final dataAt17 = MarketMapRenderData.fromFeatures(
      features,
      zoom: 17,
      center: const LatLng(42.94, 74.62),
      maxContainerFeatures: 500,
    );

    expect(
      dataAt16.renderedContainerCount,
      MarketMapRenderData.containerRenderLimitForZoom(16),
    );
    expect(
      dataAt16.polygons,
      hasLength(MarketMapRenderData.containerRenderLimitForZoom(16)),
    );
    expect(
      dataAt16.markers,
      hasLength(MarketMapRenderData.containerRenderLimitForZoom(16)),
    );

    expect(
      dataAt17.renderedContainerCount,
      MarketMapRenderData.containerRenderLimitForZoom(17),
    );
    expect(
      dataAt17.polygons,
      hasLength(MarketMapRenderData.containerRenderLimitForZoom(17)),
    );
    expect(
      dataAt17.markers,
      hasLength(MarketMapRenderData.containerRenderLimitForZoom(17)),
    );
  });

  test('feature center is precomputed once while parsing GeoJSON', () {
    final feature = MarketMapFeature.fromJson({
      'type': 'Feature',
      'id': 'container-center',
      'properties': {'kind': 'container', 'name': '1'},
      'geometry': {
        'type': 'Polygon',
        'coordinates': [
          [
            [74.62, 42.94],
            [74.64, 42.94],
            [74.64, 42.96],
            [74.62, 42.96],
            [74.62, 42.94],
          ],
        ],
      },
    });

    expect(feature.centerLat, closeTo(42.95, 0.000001));
    expect(feature.centerLon, closeTo(74.63, 0.000001));
  });

  test('container feature rendering can be disabled while map moves', () {
    final bazar = MarketMapFeature.fromJson({
      'type': 'Feature',
      'id': 'bazar-1',
      'properties': {'kind': 'bazar', 'name': 'Базар', 'min_zoom': 10},
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
    final container = MarketMapFeature.fromJson({
      'type': 'Feature',
      'id': 'container-1',
      'properties': {'kind': 'container', 'name': '1', 'min_zoom': 15},
      'geometry': {
        'type': 'Point',
        'coordinates': [74.62, 42.94],
      },
    });

    final data = MarketMapRenderData.fromFeatures(
      [bazar, container],
      zoom: 16,
      center: const LatLng(42.94, 74.62),
      maxContainerFeatures: 0,
    );

    expect(data.polygons, hasLength(1));
    expect(data.markers, hasLength(1));

    final movingData = MarketMapRenderData.fromFeatures(
      [bazar, container],
      zoom: 16,
      center: const LatLng(42.94, 74.62),
      maxContainerFeatures: 0,
      showLabels: false,
    );

    expect(movingData.polygons, hasLength(1));
    expect(movingData.markers, isEmpty);
  });
}
