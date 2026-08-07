import 'package:dogo/features/main_module/history/data/model/shipment_detail_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShipmentStop displayTitle', () {
    test('показывает базар, проход и контейнер из API', () {
      final stop = ShipmentStop.fromJson(const {
        'position': 0,
        'title': 'Дордой',
        'lat': '42.936000',
        'lon': '74.623000',
        'bazar': 'Дордой',
        'passage': '4',
        'container': '125',
        'label': 'Контейнер 125, 4 проход · Дордой',
      });

      expect(stop.displayTitle, 'Дордой · Проход 4 · Контейнер 125');
    });

    test('для старой точки сохраняет title как fallback', () {
      final stop = ShipmentStop.fromJson(const {
        'position': 1,
        'title': 'Старый адрес',
        'lat': 42.9,
        'lon': 74.6,
      });

      expect(stop.displayTitle, 'Старый адрес');
    });
  });
}
