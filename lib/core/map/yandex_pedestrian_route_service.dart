import 'dart:async';

import 'package:latlong2/latlong.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' as ymk;
import 'package:yandex_maps_mapkit/transport.dart' as ytransport;

/// Builds walking routes using the same Yandex pedestrian graph as Yandex Maps.
///
/// The native pedestrian router accepts two points per request, so a route with
/// stops is built leg-by-leg without changing their business order.
final class YandexPedestrianRouteService {
  ytransport.PedestrianRouter? _router;
  final Set<ytransport.MasstransitSession> _sessions = {};

  ytransport.PedestrianRouter get _pedestrianRouter =>
      _router ??= ytransport.TransportFactory.instance.createPedestrianRouter();

  Future<List<LatLng>> build(List<LatLng> stops) async {
    if (stops.length < 2) return const [];

    final fullRoute = <LatLng>[];
    for (var index = 0; index < stops.length - 1; index++) {
      final leg = await _buildLeg(stops[index], stops[index + 1]);
      if (leg.length < 2) return const [];
      fullRoute.addAll(fullRoute.isEmpty ? leg : leg.skip(1));
    }
    return _deduplicate(fullRoute);
  }

  Future<List<LatLng>> _buildLeg(LatLng from, LatLng to) async {
    final completer = Completer<List<LatLng>>();
    ytransport.MasstransitSession? session;

    void complete(List<LatLng> points) {
      final activeSession = session;
      if (activeSession != null) _sessions.remove(activeSession);
      if (!completer.isCompleted) completer.complete(points);
    }

    final handler = ytransport.RouteHandler(
      onMasstransitRoutes: (routes) {
        if (routes.isEmpty) {
          complete(const []);
          return;
        }
        final points = routes.first.geometry.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList(growable: false);
        complete(points);
      },
      onMasstransitRoutesError: (_) => complete(const []),
    );

    try {
      session = _pedestrianRouter.requestRoutes(
        const ytransport.TimeOptions(),
        const ytransport.RouteOptions(ytransport.FitnessOptions()),
        handler,
        points: [_requestPoint(from), _requestPoint(to)],
      );
      _sessions.add(session);
      return await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          session?.cancel();
          if (session != null) _sessions.remove(session);
          return const [];
        },
      );
    } catch (_) {
      if (session != null) _sessions.remove(session);
      return const [];
    }
  }

  ymk.RequestPoint _requestPoint(LatLng point) => ymk.RequestPoint(
    ymk.Point(latitude: point.latitude, longitude: point.longitude),
    ymk.RequestPointType.Waypoint,
    null,
    null,
    null,
  );

  List<LatLng> _deduplicate(List<LatLng> points) {
    final result = <LatLng>[];
    for (final point in points) {
      if (result.isEmpty ||
          const Distance().as(LengthUnit.Meter, result.last, point) > 0.5) {
        result.add(point);
      }
    }
    return result;
  }

  void dispose() {
    for (final session in _sessions.toList(growable: false)) {
      session.cancel();
    }
    _sessions.clear();
  }
}
