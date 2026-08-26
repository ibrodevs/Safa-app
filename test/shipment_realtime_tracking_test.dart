import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dogo/data/realtime/shipment_realtime_service.dart';

void main() {
  test('courier telemetry parses server coordinates and timestamp', () {
    final telemetry = ShipmentCourierTelemetry.tryParse({
      'type': 'telemetry',
      'shipment_id': 42,
      'courier': {
        'lat': '42.871000',
        'lon': '74.601000',
        'updated_at': '2026-08-24T10:00:00Z',
      },
    });

    expect(telemetry, isNotNull);
    expect(telemetry!.shipmentId, 42);
    expect(telemetry.lat, 42.871);
    expect(telemetry.lon, 74.601);
    expect(telemetry.updatedAt, DateTime.utc(2026, 8, 24, 10));
  });

  test('invalid courier telemetry is ignored', () {
    expect(
      ShipmentCourierTelemetry.tryParse({
        'type': 'telemetry',
        'shipment_id': 42,
        'courier': {'lat': '999', 'lon': '74.6'},
      }),
      isNull,
    );
  });

  test('client map renders live courier marker from WebSocket telemetry', () {
    final map = File(
      'lib/features/main_module/map/view/map_screen.dart',
    ).readAsStringSync();
    final carrier = File(
      'lib/features/carrier_module/home/carrier_home_screen.dart',
    ).readAsStringSync();

    expect(map, contains('ShipmentCourierTelemetry.tryParse(event)'));
    expect(map, contains('_CourierTrackingMarker'));
    expect(map, contains('point: courierPosition'));
    expect(carrier, contains('now.difference(last).inSeconds < 5'));
  });

  test('numeric backend fallback is not accepted as a readable address', () {
    final repository = File(
      'lib/features/main_module/map/data/repo/delivery_geo_repository.dart',
    ).readAsStringSync();

    expect(repository, contains("source != 'coordinates'"));
    expect(repository, contains('_addressLetter.hasMatch(address)'));
  });

  test('active carrier tracking survives backgrounding on Android and iOS', () {
    final carrier = File(
      'lib/features/carrier_module/home/carrier_home_screen.dart',
    ).readAsStringSync();
    final androidManifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    final iosPlist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(carrier, contains('foregroundNotificationConfig:'));
    expect(carrier, contains('allowBackgroundLocationUpdates: true'));
    expect(androidManifest, contains('ACCESS_BACKGROUND_LOCATION'));
    expect(androidManifest, contains('FOREGROUND_SERVICE_LOCATION'));
    expect(iosPlist, contains('<string>location</string>'));
  });
}
