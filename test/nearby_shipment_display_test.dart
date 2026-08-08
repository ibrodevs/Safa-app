import 'package:dogo/features/carrier_module/home/data/model/nearby_shipment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('specialist sees final fare when present and compact Safa stop', () {
    final shipment = NearbyShipment.fromJson({
      'id': 10,
      'public_code': 'S10',
      'status': 'pending',
      'title': 'Заказ',
      'service_type': 'delivery',
      'estimated_fare': 240,
      'final_fare': 260,
      'stops_count': 1,
      'distance_m': 300,
      'created_at': '2026-08-08T10:00:00Z',
      'stops': [
        {
          'position': 0,
          'title': 'Длинный внешний адрес',
          'bazar': 'Дордой',
          'district': 'Центральный',
          'passage': '8',
          'container': '125',
          'lat': 42.9,
          'lon': 74.6,
        },
      ],
    });

    expect(shipment.displayFare, 260);
    expect(shipment.serviceLabel, 'Доставка');
    expect(
      shipment.stops.single.compactAddress,
      'Базар: Дордой · Район: Центральный · Проход: 8 · Контейнер: 125',
    );
  });

  test('pending specialist order falls back to estimated fare', () {
    final shipment = NearbyShipment.fromJson({
      'id': 11,
      'public_code': 'S11',
      'status': 'pending',
      'title': 'Заказ',
      'service_type': 'cars',
      'estimated_fare': 180,
      'final_fare': 0,
      'distance_m': 100,
      'created_at': '2026-08-08T10:00:00Z',
      'stops': const [],
    });

    expect(shipment.displayFare, 180);
    expect(shipment.serviceLabel, 'Тачки');
  });
}
