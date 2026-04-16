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

    final settings = await _fm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (kDebugMode) {
      print('🔔 Permission: ${settings.authorizationStatus}');
    }

    await _fm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _lastToken = await _fm.getToken();
    if (kDebugMode) {
      print('🔑 FCM token: $_lastToken');
    }

    FirebaseMessaging.onMessage.listen((msg) async {
      if (kDebugMode) {
        print('📬 FG message: ${msg.data}');
      }
      await NotificationService.instance.showFromMessage(msg);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _routeFromData(msg.data);
    });
    final initial = await _fm.getInitialMessage();
    if (initial != null) {
      _routeFromData(initial.data);
    }
    _fm.onTokenRefresh.listen((t) {
      _lastToken = t;
      if (kDebugMode) {
        print('🔁 Token refreshed: $t');
      }
    });
    _inited = true;
  }

  void _routeFromData(Map<String, dynamic> data) {
    final route = _extractRoute(data);
    if (route != null && route.isNotEmpty) {
      AppRouter.router.go(route);
    }
  }

  String? _extractRoute(Map<String, dynamic> data) {
    final r = data['route']?.toString();
    if (r != null && r.isNotEmpty) {
      return r;
    }
    final dl = data['deep_link']?.toString();
    if (dl != null && dl.isNotEmpty) {
      return dl;
    }
    return null;
  }

  Future<void> subscribeTo(String topic) => _fm.subscribeToTopic(topic);

  Future<void> unsubscribeFrom(String topic) =>
      _fm.unsubscribeFromTopic(topic);

  Future<void> registerOnServerOnce({required String kind}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'fcm_registered_$kind';
    if (prefs.getBool(key) == true) {
      return;
    }

    final token = _lastToken ?? await _fm.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    final api = ApiService();
    final bearer = api.currentAccessToken;
    if (bearer == null || bearer.isEmpty) {
      return;
    }

    final platform =
    defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

    try {
      await api.postFcmRegister(
        token: token,
        platform: platform,
      );
      await prefs.setBool(key, true);
      if (kDebugMode) {
        print('FCM registered on server [$platform/$kind]');
      }
    } catch (e) {
      if (kDebugMode) {
        print('FCM register failed: $e');
      }
    }
  }
}
