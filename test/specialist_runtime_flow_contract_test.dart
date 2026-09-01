import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('waiting specialist polls every free order without a GPS gate', () {
    final source = File(
      'lib/features/carrier_module/home/carrier_home_screen.dart',
    ).readAsStringSync();
    final start = source.indexOf('Future<void> _refreshNearbySilently() async');
    final end = source.indexOf('Future<void> _goOnline() async', start);
    final body = source.substring(start, end);

    expect(body, contains('getNearbyShipments'));
    expect(body, contains('lat: _myLat'));
    expect(body, isNot(contains('_ensureLocationPermission')));
  });

  test('order alert loops bundled sound and stops stale async starts', () {
    final source = File(
      'lib/core/services/order_alert_service.dart',
    ).readAsStringSync();
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(source, contains("'songs/safa-not.mp3'"));
    expect(source, contains('ReleaseMode.loop'));
    expect(source, contains('Vibration.vibrate'));
    expect(source, contains('HapticFeedback.mediumImpact()'));
    expect(source, contains('AndroidUsageType.notificationEvent'));
    expect(source, contains('generation != _generation'));
    expect(source, contains('_activeKey != key || _generation != generation'));
    expect(pubspec, contains('- assets/songs/'));
    expect(pubspec, contains('vibration:'));
  });

  test('accepted order cannot restart alert from a stale feed response', () {
    final source = File(
      'lib/features/carrier_module/home/carrier_home_screen.dart',
    ).readAsStringSync();
    final routeService = File(
      'lib/core/map/yandex_pedestrian_route_service.dart',
    ).readAsStringSync();

    expect(source, contains('if (_hasActive || _acceptingOrder)'));
    expect(
      source,
      contains('_hasActive || _acceptingOrder ? null : _currentNearby'),
    );
    expect(source, contains('YandexPedestrianRouteService'));
    expect(routeService, contains('createPedestrianRouter()'));
    expect(routeService, isNot(contains('driving')));
    expect(source, contains('AppColors.primary'));
    expect(source, isNot(contains('color: Colors.white,\n                ),')));
  });

  test('address services show single map selection button', () {
    final source = File(
      'lib/features/main_module/map/view/components/point_picker_sheet.dart',
    ).readAsStringSync();

    expect(source, contains("label: 'Указать на карте'"));
    expect(source, contains('icon: Icons.map_outlined'));
  });

  test('avatar shows upload progress immediately after image selection', () {
    final source = File(
      'lib/features/carrier_module/profile/view/carrier_profile_screen.dart',
    ).readAsStringSync();

    final picked = source.indexOf('if (picked == null) return;');
    final uploading = source.indexOf('_uploadingAvatar = true;', picked);
    final copy = source.indexOf('.copy(', picked);
    expect(uploading, greaterThan(picked));
    expect(uploading, lessThan(copy));
    expect(source, contains("'Загрузка'"));
    expect(source, contains('_avatarUploadProgress * 100'));
  });

  test('active route is current GPS position to current stop only', () {
    final source = File(
      'lib/features/carrier_module/home/carrier_home_screen.dart',
    ).readAsStringSync();
    final start = source.indexOf(
      'Future<void> _syncRouteAndCameraForActive() async',
    );
    final end = source.indexOf('Future<void> _syncRouteAndCameraCommon', start);
    final body = source.substring(start, end);

    expect(body, contains('_activeCurrentStopIndex.clamp'));
    expect(
      body,
      contains(
        'final pts = <LatLng>[LatLng(_myLat, _myLon), stopPoints[targetIndex]];',
      ),
    );
    expect(source, contains('_fittedStopIndex != targetIndex'));
    expect(source, contains("id: 'carrier-me'"));
  });
}
