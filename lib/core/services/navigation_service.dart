import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

enum NavigationRouteType {
  auto('auto'),
  pedestrian('pd'),
  bicycle('bc'),
  transit('mt');

  final String code;
  const NavigationRouteType(this.code);
}

enum NavigationLaunchResult {
  launchedNavigator,
  launchedMaps,
  launchedWeb,
  notInstalled,
  invalidCoordinates,
  error,
}

class NavigationService {
  NavigationService._();
  static final NavigationService instance = NavigationService._();

  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=ru.yandex.yandexmaps';
  static const String _appStoreUrl =
      'https://apps.apple.com/app/yandex-maps/id313877526';

  /// Validates that given coordinates are finite and non-zero.
  bool isValidCoordinate(LatLng? point) {
    if (point == null) return false;
    if (!point.latitude.isFinite || !point.longitude.isFinite) return false;
    if (point.latitude.abs() > 90 || point.longitude.abs() > 180) return false;
    if (point.latitude == 0 && point.longitude == 0) return false;
    return true;
  }

  /// Builds the deep link URI for Yandex Navigator.
  Uri buildYandexNavigatorUri({required LatLng destination, LatLng? origin}) {
    final queryParams = <String, String>{
      'lat_to': destination.latitude.toString(),
      'lon_to': destination.longitude.toString(),
    };

    if (isValidCoordinate(origin)) {
      queryParams['lat_from'] = origin!.latitude.toString();
      queryParams['lon_from'] = origin.longitude.toString();
    }

    return Uri(
      scheme: 'yandexnavi',
      host: 'build_route_on_map',
      queryParameters: queryParams,
    );
  }

  /// Builds the deep link URI for Yandex Maps application.
  ///
  /// [routeType] defaults to [NavigationRouteType.pedestrian] ('pd') to build
  /// exact routes through internal market passages and aisles (like Dordoy).
  Uri buildYandexMapsUri({
    required LatLng destination,
    LatLng? origin,
    List<LatLng>? stops,
    NavigationRouteType routeType = NavigationRouteType.pedestrian,
  }) {
    final routePoints = <String>[];
    if (isValidCoordinate(origin)) {
      routePoints.add('${origin!.latitude},${origin.longitude}');
    }

    if (stops != null && stops.isNotEmpty) {
      for (final stop in stops) {
        if (isValidCoordinate(stop)) {
          routePoints.add('${stop.latitude},${stop.longitude}');
        }
      }
    }

    // Ensure destination is at the end if not already included
    final destStr = '${destination.latitude},${destination.longitude}';
    if (routePoints.isEmpty || routePoints.last != destStr) {
      routePoints.add(destStr);
    }

    return Uri.parse(
      'yandexmaps://maps.yandex.ru/?rtext=${routePoints.join('~')}&rtt=${routeType.code}',
    );
  }

  /// Builds the web browser URI for Yandex Maps.
  ///
  /// [routeType] defaults to [NavigationRouteType.pedestrian] ('pd') to build
  /// exact routes through internal market passages and aisles (like Dordoy).
  Uri buildYandexWebMapsUri({
    required LatLng destination,
    LatLng? origin,
    List<LatLng>? stops,
    NavigationRouteType routeType = NavigationRouteType.pedestrian,
  }) {
    final routePoints = <String>[];
    if (isValidCoordinate(origin)) {
      routePoints.add('${origin!.latitude},${origin.longitude}');
    }

    if (stops != null && stops.isNotEmpty) {
      for (final stop in stops) {
        if (isValidCoordinate(stop)) {
          routePoints.add('${stop.latitude},${stop.longitude}');
        }
      }
    }

    final destStr = '${destination.latitude},${destination.longitude}';
    if (routePoints.isEmpty || routePoints.last != destStr) {
      routePoints.add(destStr);
    }

    return Uri.parse(
      'https://yandex.ru/maps/?rtext=${routePoints.join('~')}&rtt=${routeType.code}',
    );
  }

  /// Checks if Yandex Navigator app is installed on the device.
  Future<bool> isYandexNavigatorInstalled() async {
    try {
      final uri = Uri(scheme: 'yandexnavi', host: 'build_route_on_map');
      return await canLaunchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  /// Checks if Yandex Maps app is installed on the device.
  Future<bool> isYandexMapsInstalled() async {
    try {
      final uri = Uri(scheme: 'yandexmaps', host: 'maps.yandex.ru');
      return await canLaunchUrl(uri);
    } catch (_) {
      return false;
    }
  }

  /// Opens route in Yandex Maps or Yandex Navigator, building full pedestrian
  /// passage routes or automotive road routes.
  ///
  /// [destination]: Target destination coordinates (must be valid).
  /// [origin]: Specialist's current coordinates (optional).
  /// [stops]: Optional list of intermediate/subsequent stops.
  /// [routeType]: [NavigationRouteType.pedestrian] ('pd') for walking through
  ///   market passages/pavilions, or [NavigationRouteType.auto] for driving.
  /// [allowFallback]: Whether to automatically fall back to Yandex Maps / Web.
  Future<NavigationLaunchResult> openYandexNavigator({
    required LatLng destination,
    LatLng? origin,
    List<LatLng>? stops,
    NavigationRouteType routeType = NavigationRouteType.pedestrian,
    bool allowFallback = true,
  }) async {
    if (!isValidCoordinate(destination)) {
      return NavigationLaunchResult.invalidCoordinates;
    }

    try {
      // 1. If pedestrian mode is desired (default for market/local routes),
      // Yandex Maps app natively understands internal aisles, passages, and pavilions.
      final mapsUri = buildYandexMapsUri(
        destination: destination,
        origin: origin,
        stops: stops,
        routeType: routeType,
      );

      final canOpenMaps = await canLaunchUrl(mapsUri);
      if (canOpenMaps) {
        final launched = await launchUrl(
          mapsUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) {
          return NavigationLaunchResult.launchedMaps;
        }
      }

      // Yandex Navigator only builds automotive routes. Never silently switch
      // a specialist from walking to driving when Maps is unavailable.
      if (routeType == NavigationRouteType.auto) {
        final navigatorUri = buildYandexNavigatorUri(
          destination: destination,
          origin: origin,
        );

        final canOpenNavigator = await canLaunchUrl(navigatorUri);
        if (canOpenNavigator) {
          final launched = await launchUrl(
            navigatorUri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) {
            return NavigationLaunchResult.launchedNavigator;
          }
        }
      }

      if (!allowFallback) {
        return NavigationLaunchResult.notInstalled;
      }

      // 3. Fallback: Web browser Yandex Maps (exactly as shown on the website with passages)
      final webUri = buildYandexWebMapsUri(
        destination: destination,
        origin: origin,
        stops: stops,
        routeType: routeType,
      );

      final launchedWeb = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
      if (launchedWeb) {
        return NavigationLaunchResult.launchedWeb;
      }

      return NavigationLaunchResult.notInstalled;
    } catch (e) {
      debugPrint('NavigationService error: $e');
      return NavigationLaunchResult.error;
    }
  }

  /// Opens the store page to download Yandex Maps / Navigator.
  Future<bool> openStorePage() async {
    try {
      Uri storeUri;
      if (!kIsWeb && Platform.isIOS) {
        storeUri = Uri.parse(_appStoreUrl);
      } else {
        storeUri = Uri.parse(_playStoreUrl);
      }
      return await launchUrl(storeUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
