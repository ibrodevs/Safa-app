import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('client and specialist use compact hierarchy and server fare', () {
    final nearby = File('lib/features/carrier_module/home/data/model/nearby_shipment.dart').readAsStringSync();
    final carrier = File('lib/features/carrier_module/home/carrier_home_screen.dart').readAsStringSync();
    final point = File('lib/features/main_module/map/data/model/delivery_point_model.dart').readAsStringSync();
    final summary = File('lib/features/main_module/map/view/components/order_summary_sheet.dart').readAsStringSync();
    expect(nearby, contains('final String? district;'));
    expect(nearby, contains('String get compactAddress'));
    expect(nearby, contains('int get displayFare'));
    expect(carrier, contains("j['final_fare']"));
    expect(carrier, contains('shipment.displayFare'));
    expect(carrier, contains('shipment.stops[i].compactAddress'));
    expect(point, contains('String get compactTitle'));
    expect(summary, contains('title: stops[i].compactTitle'));
  });

  test('specialist map refreshes published containers for viewport', () {
    final source = File('lib/features/carrier_module/home/carrier_home_screen.dart').readAsStringSync();
    expect(source, contains('_refreshMarketMapForViewport'));
    expect(source, contains('onMapReady:'));
    expect(source, contains('maxContainers: 192'));
  });

  test('notifications are role-aware and hide technical tags', () {
    final screen = File('lib/features/main_module/profile/view/components/profile_notifications_screen.dart').readAsStringSync();
    final router = File('lib/core/router/app_router.dart').readAsStringSync();
    final profile = File('lib/features/carrier_module/profile/view/carrier_profile_screen.dart').readAsStringSync();
    expect(screen, contains('if (widget.isCarrier)'));
    expect(screen, isNot(contains('class _Tag extends StatelessWidget')));
    expect(screen, isNot(contains('Источник: сервер')));
    expect(router, contains("queryParameters['role'] ?? 'client'"));
    expect(profile, contains('/profile/notifications?role=carrier'));
  });
}
