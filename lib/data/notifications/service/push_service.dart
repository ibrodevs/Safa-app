import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/network/api_service.dart';
import 'notification_router.dart';
import 'notification_service.dart';

class PushService {
  PushService._();

  static final PushService instance = PushService._();

  final FirebaseMessaging _fm = FirebaseMessaging.instance;
  bool _inited = false;
  String? _lastToken;
  String? _activeKind;
  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _events.stream;

  Future<void> init() async {
    if (_inited) return;

    await _fm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Foreground notifications are rendered by NotificationService on both
    // platforms. Keeping native iOS presentation off avoids duplicate banners
    // now that backend messages also contain an OS-visible notification block.
    await _fm.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    _lastToken = await _fm.getToken();

    FirebaseMessaging.onMessage.listen((msg) async {
      _events.add(Map<String, dynamic>.from(msg.data));
      if (msg.data['silent']?.toString() == '1') return;
      await NotificationService.instance.showFromMessage(msg);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _events.add(Map<String, dynamic>.from(msg.data));
      NotificationRouter.routeFromData(msg.data);
    });
    final initial = await _fm.getInitialMessage();
    if (initial != null) {
      NotificationRouter.routeFromData(initial.data);
    }

    _fm.onTokenRefresh.listen((token) async {
      _lastToken = token;
      final prefs = await SharedPreferences.getInstance();
      await _clearRegistrationCache(prefs);

      // Token rotation can happen while the user keeps the home screen open.
      // Register the replacement immediately instead of waiting for another
      // login/navigation cycle.
      final kind = _activeKind;
      if (kind != null && kind.isNotEmpty) {
        unawaited(_registerTokenOnServer(token: token, kind: kind));
      }
    });
    _inited = true;
  }

  Future<void> subscribeTo(String topic) => _fm.subscribeToTopic(topic);

  Future<void> unsubscribeFrom(String topic) => _fm.unsubscribeFromTopic(topic);

  Future<void> registerOnServerOnce({required String kind}) async {
    _activeKind = kind;
    String? token = _lastToken;
    try {
      token ??= await _fm.getToken();
    } catch (_) {
      return;
    }
    if (token == null || token.isEmpty) return;
    _lastToken = token;
    await _registerTokenOnServer(token: token, kind: kind);
  }

  Future<void> _registerTokenOnServer({
    required String token,
    required String kind,
  }) async {
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
      // Следующий вход на домашний экран или refresh токена повторит регистрацию.
    }
  }

  Future<void> unregisterCurrentDevice() async {
    final api = ApiService();
    String? token = _lastToken;
    try {
      token ??= await _fm.getToken();
    } catch (_) {}

    // Unregister while the access token still exists. The backend then stops
    // sending to this account immediately instead of waiting for FCM to reject
    // a stale registration token.
    if (token != null &&
        token.isNotEmpty &&
        api.currentAccessToken?.isNotEmpty == true) {
      try {
        await api.dio.delete<dynamic>(
          'fcm/unregister/',
          data: {'token': token},
        );
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await _clearRegistrationCache(prefs);
    _lastToken = null;
    _activeKind = null;

    try {
      await _fm.deleteToken();
    } catch (_) {}
  }

  Future<void> _clearRegistrationCache(SharedPreferences prefs) async {
    await prefs.remove('fcm_registered_token_client');
    await prefs.remove('fcm_registered_token_carrier');
  }
}
