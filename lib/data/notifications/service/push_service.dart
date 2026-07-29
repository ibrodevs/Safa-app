import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/router/app_router.dart';
import '../../../data/network/api_service.dart';
import 'notification_service.dart';

class PushService {
  PushService._();

  static final PushService instance = PushService._();

  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  bool _inited = false;
  String? _lastToken;

  Future<void> init() async {
    if (_inited) return;

    await _fm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _fm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _lastToken = await _fm.getToken();

    FirebaseMessaging.onMessage.listen((msg) async {
      await NotificationService.instance.showFromMessage(msg);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _routeFromData(msg.data);
    });
    final initial = await _fm.getInitialMessage();
    if (initial != null) {
      _routeFromData(initial.data);
    }

    _fm.onTokenRefresh.listen((token) async {
      _lastToken = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_registered_token_client');
      await prefs.remove('fcm_registered_token_carrier');
    });
    _inited = true;
  }

  void _routeFromData(Map<String, dynamic> data) {
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
    if (route != null && route.startsWith('/')) {
      AppRouter.router.go(route);
    }
  }

  String? _extractRoute(Map<String, dynamic> data) {
    final route = data['route']?.toString();
    if (route != null && route.isNotEmpty) return route;
    final deepLink = data['deep_link']?.toString();
    if (deepLink != null && deepLink.startsWith('/')) return deepLink;
    return null;
  }

  Future<void> subscribeTo(String topic) => _fm.subscribeToTopic(topic);

  Future<void> unsubscribeFrom(String topic) => _fm.unsubscribeFromTopic(topic);

  Future<void> registerOnServerOnce({required String kind}) async {
    final token = _lastToken ?? await _fm.getToken();
    if (token == null || token.isEmpty) return;

    final api = ApiService();
    final bearer = api.currentAccessToken;
    if (bearer == null || bearer.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = 'fcm_registered_token_$kind';
    if (prefs.getString(key) == token) return;

    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';

    try {
      await api.postFcmRegister(token: token, platform: platform);
      await prefs.setString(key, token);
    } catch (_) {
      // Следующий вход на домашний экран повторит регистрацию.
    }
  }
}
