import '../../../core/router/app_router.dart';

final class NotificationRouter {
  NotificationRouter._();

  static void routeFromData(Map<String, dynamic> data) {
    final app = data['app']?.toString().toLowerCase();
    final shipmentId = int.tryParse(data['shipment_id']?.toString() ?? '');

    if (app == 'client' && shipmentId != null) {
      AppRouter.router.go('/history/detail', extra: shipmentId);
      return;
    }
    if (app == 'carrier') {
      AppRouter.router.go('/home-carrier');
      return;
    }

    final route = _extractRoute(data);
    if (route == null || route.isEmpty) return;

    if (route.startsWith('/')) {
      AppRouter.router.go(route);
      return;
    }

    final uri = Uri.tryParse(route);
    if (uri == null || uri.scheme != 'app') return;

    final targetApp = uri.host.toLowerCase();
    final segments = uri.pathSegments;
    if (targetApp == 'client') {
      if (segments.length >= 2 && segments.first == 'shipment') {
        final id = int.tryParse(segments[1]);
        if (id != null) {
          AppRouter.router.go('/history/detail', extra: id);
          return;
        }
      }
      AppRouter.router.go('/home');
      return;
    }

    if (targetApp == 'carrier') {
      AppRouter.router.go('/home-carrier');
    }
  }

  static String? _extractRoute(Map<String, dynamic> data) {
    final route = data['route']?.toString();
    if (route != null && route.isNotEmpty) return route;
    final deepLink = data['deep_link']?.toString();
    if (deepLink != null && deepLink.isNotEmpty) return deepLink;
    return null;
  }
}
