import 'dart:io';

import 'package:dogo/features/main_module/map/data/model/delivery_point_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Маршруты раздела «Тачки»', () {
    test('сохраняют порядок двух и более точек', () {
      const points = <DeliveryPoint>[
        DeliveryPoint(
          title: 'Начальная точка',
          subtitle: '',
          lat: 42.8746,
          lon: 74.6122,
        ),
        DeliveryPoint(
          title: 'Промежуточная точка 1',
          subtitle: '',
          lat: 42.88,
          lon: 74.62,
        ),
        DeliveryPoint(
          title: 'Промежуточная точка 2',
          subtitle: '',
          lat: 42.89,
          lon: 74.63,
        ),
        DeliveryPoint(
          title: 'Конечная точка',
          subtitle: '',
          lat: 42.9,
          lon: 74.64,
        ),
      ];

      final payload = points.map((point) => point.toStopJson()).toList();

      expect(payload, hasLength(4));
      expect(
        payload.map((point) => point['title']),
        orderedEquals(<String>[
          'Начальная точка',
          'Промежуточная точка 1',
          'Промежуточная точка 2',
          'Конечная точка',
        ]),
      );
      expect(payload.every((point) => point['lat'] != null), isTrue);
      expect(payload.every((point) => point['lon'] != null), isTrue);
    });

    test('весь порядок A-B-C уходит в один дорожный запрос', () {
      final router = File(
        'lib/core/map/optimal_road_route_service.dart',
      ).readAsStringSync();
      final map = File(
        'lib/features/main_module/map/view/map_screen.dart',
      ).readAsStringSync();

      expect(router, contains(".join(';')"));
      expect(router, contains('route/v1/driving/'));
      expect(router, contains("List.filled(stops.length, 'unlimited')"));
      expect(router, contains("'alternatives': '3'"));
      expect(map, contains('return _roadRouter.build(pts);'));
      expect(router, isNot(contains("['foot', 'walking', 'driving']")));
      expect(map, isNot(contains('route.isNotEmpty ? route : pts')));
    });

    test('передают данные выбранного контейнера в заказ', () {
      const point = DeliveryPoint(
        title: 'Дордой',
        subtitle: 'Контейнер: 125 • Проход: 4',
        lat: 42.936,
        lon: 74.623,
        bazar: 'Дордой',
        passage: '4',
        container: '125',
      );

      final payload = point.toStopJson();

      expect(payload['bazar'], 'Дордой');
      expect(payload['passage'], '4');
      expect(payload['container'], '125');
      expect(payload['lat'], 42.936);
      expect(payload['lon'], 74.623);
    });

    test('восстанавливают контейнер после выбора на карте', () {
      const pointRebuiltBySheet = DeliveryPoint(
        title: 'Дордой',
        subtitle: 'Контейнер 125 • Проход 4',
        lat: 42.936,
        lon: 74.623,
        bazar: '',
        passage: '',
        container: '',
      );

      final payload = pointRebuiltBySheet.toStopJson();

      expect(payload['bazar'], 'Дордой');
      expect(payload['passage'], '4');
      expect(payload['container'], '125');
    });
  });
}
