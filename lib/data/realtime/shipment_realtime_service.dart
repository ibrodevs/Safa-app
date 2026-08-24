import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../network/api_service.dart';

final class ShipmentCourierTelemetry {
  const ShipmentCourierTelemetry({
    required this.shipmentId,
    required this.lat,
    required this.lon,
    required this.updatedAt,
  });

  final int shipmentId;
  final double lat;
  final double lon;
  final DateTime? updatedAt;

  static ShipmentCourierTelemetry? tryParse(Map<String, dynamic> event) {
    if (event['type']?.toString() != 'telemetry') return null;
    final shipmentId = int.tryParse(event['shipment_id']?.toString() ?? '');
    final rawCourier = event['courier'];
    if (shipmentId == null || rawCourier is! Map) return null;
    final courier = Map<String, dynamic>.from(rawCourier);
    final lat = double.tryParse(courier['lat']?.toString() ?? '');
    final lon = double.tryParse(courier['lon']?.toString() ?? '');
    if (lat == null ||
        lon == null ||
        !lat.isFinite ||
        !lon.isFinite ||
        lat < -90 ||
        lat > 90 ||
        lon < -180 ||
        lon > 180) {
      return null;
    }
    return ShipmentCourierTelemetry(
      shipmentId: shipmentId,
      lat: lat,
      lon: lon,
      updatedAt: DateTime.tryParse(courier['updated_at']?.toString() ?? ''),
    );
  }
}

/// Keeps one authenticated shipment WebSocket alive and reconnects after
/// transient network/app lifecycle interruptions.
final class ShipmentRealtimeService {
  ShipmentRealtimeService({required this.onEvent});

  final void Function(Map<String, dynamic> event) onEvent;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retryTimer;
  Timer? _pingTimer;
  int? _shipmentId;
  int _transportGeneration = 0;
  bool _disposed = false;

  void connect(int shipmentId) {
    if (_disposed) return;
    if (_shipmentId == shipmentId && _channel != null) return;
    _closeTransport();
    _shipmentId = shipmentId;
    _open();
  }

  void reconnect() {
    if (_shipmentId == null || _disposed) return;
    _closeTransport();
    _open();
  }

  void _open() {
    final shipmentId = _shipmentId;
    final token = ApiService.instance.currentAccessToken;
    if (_disposed || shipmentId == null) return;
    if (token == null || token.isEmpty) {
      _scheduleRetry();
      return;
    }

    final apiUri = Uri.parse(ApiService.instance.dio.options.baseUrl);
    final uri = apiUri.replace(
      scheme: apiUri.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws/shipments/$shipmentId/',
      queryParameters: {'token': token},
    );
    try {
      final generation = ++_transportGeneration;
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        if (generation != _transportGeneration) return;
        channel.sink.add(jsonEncode({'type': 'ping'}));
      });
      _subscription = channel.stream.listen(
        (raw) {
          try {
            final decoded = raw is String ? jsonDecode(raw) : raw;
            if (decoded is Map) {
              onEvent(Map<String, dynamic>.from(decoded));
            }
          } catch (_) {
            // Polling remains the fallback for malformed/non-JSON frames.
          }
        },
        onError: (_) {
          if (generation != _transportGeneration) return;
          _channel = null;
          _scheduleRetry();
        },
        onDone: () {
          if (generation != _transportGeneration) return;
          _channel = null;
          _scheduleRetry();
        },
        cancelOnError: true,
      );
    } catch (_) {
      _channel = null;
      _subscription = null;
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    if (_disposed || _shipmentId == null || _retryTimer?.isActive == true) {
      return;
    }
    _retryTimer = Timer(const Duration(seconds: 3), _open);
  }

  void _closeTransport() {
    _transportGeneration++;
    _retryTimer?.cancel();
    _retryTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void disconnect() {
    _shipmentId = null;
    _closeTransport();
  }

  void dispose() {
    _disposed = true;
    disconnect();
  }
}
