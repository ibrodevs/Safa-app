import 'package:dogo/features/main_module/map/data/model/delivery_point_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Safa hierarchy stays short and ordered', () {
    const point = DeliveryPoint(
      title: 'Старый длинный адрес, который не должен показываться',
      subtitle: '',
      bazar: 'Дордой',
      district: 'Центральный',
      passage: '8',
      container: '125',
      lat: 42.9,
      lon: 74.6,
    );

    expect(point.compactTitle, 'Базар: Дордой · Район: Центральный');
    expect(point.compactSubtitle, 'Проход: 8 · Контейнер: 125');
    expect(
      point.compactAddress,
      'Базар: Дордой · Район: Центральный · Проход: 8 · Контейнер: 125',
    );
  });

  test('hierarchy can be parsed from backend label', () {
    const point = DeliveryPoint(
      title:
          'Базар: Дордой · Район: Западный · Проход: 4 · Контейнер: 77',
      subtitle: '',
    );

    expect(point.bazar, 'Дордой');
    expect(point.district, 'Западный');
    expect(point.passage, '4');
    expect(point.container, '77');
  });
}
