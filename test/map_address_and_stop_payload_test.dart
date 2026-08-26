import 'package:dogo/core/utils/address_format.dart';
import 'package:dogo/features/main_module/map/data/model/delivery_point_model.dart';
import 'package:dogo/features/main_module/map/data/model/delivery_reverse_geo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Адрес для подписи точки', () {
    test('без почтового индекса и страны', () {
      expect(
        formatReadableAddress('12, Байтик Баатыра, Бишкек, 720000, Кыргызстан'),
        '12, Байтик Баатыра, Бишкек',
      );
    });

    test('индекс, приклеенный к городу, тоже убирается', () {
      expect(
        formatReadableAddress('Кожевенная улица, 720044 Бишкек, Кыргызстан'),
        'Кожевенная улица, Бишкек',
      );
    });

    test('чистится и то, что пришло от backend', () {
      final geo = DeliveryReverseGeo.fromJson({
        'address': 'Дордой, Бишкек, 720044, Кыргызстан',
      });

      expect(geo.address, 'Дордой, Бишкек');
    });

    test('компоненты склеиваются без дублей и мусора', () {
      expect(
        joinAddressParts(['Бишкек', 'Бишкек', '', 'Кожевенная улица', '1']),
        'Бишкек, Кожевенная улица, 1',
      );
    });
  });

  group('Точка с карты уходит на backend без ложного контейнера', () {
    test('слово «базар» внутри адреса не становится полем bazar', () {
      const point = DeliveryPoint(
        title: 'Дордой базар, Кожевенная улица, 1',
        subtitle: 'Дордой базар, Кожевенная улица, 1',
        lat: 42.9312,
        lon: 74.6087,
        bazar: '',
        passage: '',
        container: '',
      );

      expect(point.bazar, isNull);
      expect(point.hasFullContainerAddress, isFalse);

      final json = point.toStopJson();
      expect(json['bazar'], '');
      expect(json['passage'], '');
      expect(json['container'], '');
      expect(json['title'], 'Дордой базар, Кожевенная улица, 1');
    });

    test('неполный контейнер не отправляется частями', () {
      const point = DeliveryPoint(
        title: 'Дордой',
        subtitle: 'Контейнер: 125',
        lat: 42.9312,
        lon: 74.6087,
        bazar: 'Дордой',
        container: '125',
      );

      expect(point.hasFullContainerAddress, isFalse);

      final json = point.toStopJson();
      expect(json['bazar'], '');
      expect(json['container'], '');
      expect(json['lat'], 42.9312);
    });

    test('полный контейнер уходит всеми тремя полями', () {
      const point = DeliveryPoint(
        title: 'Дордой',
        subtitle: 'Контейнер: 125 • Проход: 8',
        lat: 42.9312,
        lon: 74.6087,
        bazar: 'Дордой',
        passage: '8',
        container: '125',
      );

      final json = point.toStopJson();
      expect(json['bazar'], 'Дордой');
      expect(json['passage'], '8');
      expect(json['container'], '125');
    });

    test('длинная подпись обрезается до лимита backend', () {
      final point = DeliveryPoint(
        title: 'А' * 400,
        subtitle: '',
        lat: 42.9,
        lon: 74.6,
      );

      expect((point.toStopJson()['title'] as String).length, 255);
    });
  });
}
