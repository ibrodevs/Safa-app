// lib/data/notifications/service/push_service.dart
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/router/app_router.dart';
import '../../../data/network/api_service.dart';

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  StreamSubscription<RemoteMessage>? _fgSub;
  bool _inited = false;

  String? _lastToken;

  Future<void> init() async {
    if (_inited) return;

    final settings = await _fm.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
    if (kDebugMode) print('🔔 Permission: ${settings.authorizationStatus}');

    await _fm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    _lastToken = await _fm.getToken();
    if (kDebugMode) print('🔑 FCM token: $_lastToken');

    await registerFcmIfPossible(app: 'passenger');

    _fm.onTokenRefresh.listen((t) {
      _lastToken = t;
      if (kDebugMode) print('🔁 Token refreshed: $t');
      unawaited(registerFcmIfPossible(app: 'passenger'));
    });

    _fgSub = FirebaseMessaging.onMessage.listen((msg) async {});

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _routeFromData(msg.data);
    });

    final initial = await _fm.getInitialMessage();
    if (initial != null) {
      _routeFromData(initial.data);
    }

    _inited = true;
  }

  void _routeFromData(Map<String, dynamic> data) {
    final route = data['route']?.toString();
    if (route != null && route.isNotEmpty) {
     /* AppRouterNav.pushFromOutside(route);*/
    }
  }

  Future<void> subscribeTo(String topic) => _fm.subscribeToTopic(topic);
  Future<void> unsubscribeFrom(String topic) => _fm.unsubscribeFromTopic(topic);

  Future<void> registerFcmIfPossible({String app = 'passenger'}) async {
    final token = _lastToken ?? await _fm.getToken();
    if (token == null || token.isEmpty) return;

    final api = ApiService();
    final bearer = api.currentAccessToken;
    if (bearer == null || bearer.isEmpty) return;

    final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
    final l = ui.PlatformDispatcher.instance.locale;
    final locale = l.languageCode + (l.countryCode == null ? '' : '-${l.countryCode}');

    try {
      await api.postFcmRegister(
        token: token,
        platform: platform,
        app: app,
        locale: locale.isEmpty ? null : locale,
      );
      if (kDebugMode) print('📮 FCM registered on server [$platform/$app]');
    } catch (e) {
      if (kDebugMode) print('⚠️ FCM register failed: $e');
    }
  }
}
