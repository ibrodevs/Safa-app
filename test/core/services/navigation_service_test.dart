import 'package:dogo/core/services/navigation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('NavigationService tests', () {
    final nav = NavigationService.instance;

    test('isValidCoordinate validation', () {
      expect(nav.isValidCoordinate(null), isFalse);
      expect(nav.isValidCoordinate(const LatLng(0, 0)), isFalse);
      expect(nav.isValidCoordinate(const LatLng(100, 50)), isFalse);
      expect(nav.isValidCoordinate(const LatLng(42.8746, 200)), isFalse);

      expect(nav.isValidCoordinate(const LatLng(42.8746, 74.6122)), isTrue);
      expect(nav.isValidCoordinate(const LatLng(42.9345678, 74.6234567)), isTrue);
    });

    test('buildYandexNavigatorUri with destination and origin (full precision)', () {
      final destination = const LatLng(42.9345678, 74.6234567);
      final origin = const LatLng(42.8746123, 74.6122987);

      final uri = nav.buildYandexNavigatorUri(
        destination: destination,
        origin: origin,
      );

      expect(uri.scheme, 'yandexnavi');
      expect(uri.host, 'build_route_on_map');
      expect(uri.queryParameters['lat_to'], '42.9345678');
      expect(uri.queryParameters['lon_to'], '74.6234567');
      expect(uri.queryParameters['lat_from'], '42.8746123');
      expect(uri.queryParameters['lon_from'], '74.6122987');
    });

    test('buildYandexNavigatorUri without origin', () {
      final destination = const LatLng(42.9345678, 74.6234567);

      final uri = nav.buildYandexNavigatorUri(
        destination: destination,
      );

      expect(uri.scheme, 'yandexnavi');
      expect(uri.host, 'build_route_on_map');
      expect(uri.queryParameters['lat_to'], '42.9345678');
      expect(uri.queryParameters['lon_to'], '74.6234567');
      expect(uri.queryParameters.containsKey('lat_from'), isFalse);
      expect(uri.queryParameters.containsKey('lon_from'), isFalse);
    });

    test('buildYandexMapsUri defaults to pedestrian routing (rtt=pd)', () {
      final destination = const LatLng(42.9345678, 74.6234567);
      final origin = const LatLng(42.8746, 74.6122);

      final uri = nav.buildYandexMapsUri(
        destination: destination,
        origin: origin,
      );

      expect(uri.scheme, 'yandexmaps');
      expect(uri.host, 'maps.yandex.ru');
      expect(uri.queryParameters['rtext'], '42.8746,74.6122~42.9345678,74.6234567');
      expect(uri.queryParameters['rtt'], 'pd');
    });

    test('buildYandexMapsUri multi-stop route', () {
      final destination = const LatLng(42.95, 74.65);
      final origin = const LatLng(42.87, 74.61);
      final stops = [const LatLng(42.90, 74.62), const LatLng(42.92, 74.63)];

      final uri = nav.buildYandexMapsUri(
        destination: destination,
        origin: origin,
        stops: stops,
        routeType: NavigationRouteType.auto,
      );

      expect(uri.scheme, 'yandexmaps');
      expect(
        uri.queryParameters['rtext'],
        '42.87,74.61~42.9,74.62~42.92,74.63~42.95,74.65',
      );
      expect(uri.queryParameters['rtt'], 'auto');
    });

    test('buildYandexWebMapsUri web fallback link defaults to pedestrian', () {
      final destination = const LatLng(42.9345678, 74.6234567);
      final origin = const LatLng(42.8746, 74.6122);

      final uri = nav.buildYandexWebMapsUri(
        destination: destination,
        origin: origin,
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'yandex.ru');
      expect(uri.path, '/maps/');
      expect(uri.queryParameters['rtext'], '42.8746,74.6122~42.9345678,74.6234567');
      expect(uri.queryParameters['rtt'], 'pd');
    });

    test('openYandexNavigator rejects invalid destination coordinates', () async {
      final result = await nav.openYandexNavigator(
        destination: const LatLng(0, 0),
      );
      expect(result, NavigationLaunchResult.invalidCoordinates);
    });
  });
}
