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
  Future<void>? _initFuture;
  String? _lastToken;
  String? _activeKind;
  Timer? _registrationRetryTimer;
  final Set<String> _registeredThisSession = <String>{};
  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _events.stream;

  Future<void> init() async {
    if (_inited) return;
    final pending = _initFuture;
    if (pending != null) return pending;

    final future = _initialize();
    _initFuture = future;
    try {
      await future;
    } finally {
      if (identical(_initFuture, future)) _initFuture = null;
    }
  }

  Future<void> _initialize() async {
    try {
      await _fm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (_) {}

    // Foreground notifications are rendered by NotificationService on both
    // platforms. Keeping native iOS presentation off avoids duplicate banners
    // now that backend messages also contain an OS-visible notification block.
    try {
      await _fm.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
    } catch (_) {}

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
      _registeredThisSession.clear();
      _registrationRetryTimer?.cancel();
      final prefs = await SharedPreferences.getInstance();
      await _clearRegistrationCache(prefs);

      // Token rotation can happen while the user keeps the home screen open.
      // Register the replacement immediately instead of waiting for another
      // login/navigation cycle.
      final kind = _activeKind;
      if (kind != null && kind.isNotEmpty) {
        if (kind == 'carrier_pending') {
          unawaited(_registerPendingCarrierToken(token));
        } else {
          unawaited(_registerTokenOnServer(token: token, kind: kind));
        }
      }
    });
    _inited = true;
    _lastToken = await _readTokenWithRetry();
  }

  Future<String?> _readTokenWithRetry({int attempts = 5}) async {
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          final apnsToken = await _fm.getAPNSToken();
          if (apnsToken == null || apnsToken.isEmpty) {
            await Future<void>.delayed(const Duration(seconds: 1));
            continue;
          }
        }
        final token = await _fm.getToken();
        if (token != null && token.isNotEmpty) return token;
      } catch (_) {}
      if (attempt < attempts - 1) {
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    return null;
  }

  Future<void> subscribeTo(String topic) => _fm.subscribeToTopic(topic);

  Future<void> unsubscribeFrom(String topic) => _fm.unsubscribeFromTopic(topic);

  Future<void> registerOnServerOnce({required String kind}) async {
    await init();
    _activeKind = kind;
    String? token = _lastToken;
    token ??= await _readTokenWithRetry();
    if (token == null || token.isEmpty) {
      _scheduleRegistrationRetry(kind);
      return;
    }
    _lastToken = token;
    await _registerTokenOnServer(token: token, kind: kind);
  }

  Future<void> refreshRegistration() async {
    final kind = _activeKind;
    if (kind == null || kind.isEmpty) return;
    _registeredThisSession.clear();
    await registerOnServerOnce(kind: kind);
  }

  void _scheduleRegistrationRetry(String kind) {
    _registrationRetryTimer?.cancel();
    _registrationRetryTimer = Timer(const Duration(seconds: 8), () {
      if (_activeKind == kind) {
        unawaited(registerOnServerOnce(kind: kind));
      }
    });
  }

  Future<void> registerPendingCarrier() async {
    await init();
    _activeKind = 'carrier_pending';
    String? token = _lastToken;
    token ??= await _readTokenWithRetry();
    if (token == null || token.isEmpty) {
      _scheduleRegistrationRetry('carrier_pending');
      return;
    }
    _lastToken = token;
    await _registerPendingCarrierToken(token);
  }

  Future<void> _registerPendingCarrierToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'fcm_registered_token_carrier_pending';
    final sessionKey = 'carrier_pending|$token';
    if (_registeredThisSession.contains(sessionKey)) return;
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';
    try {
      await ApiService().postPendingKycFcmRegister(
        token: token,
        platform: platform,
      );
      await prefs.setString(key, token);
      _registeredThisSession.add(sessionKey);
      _registrationRetryTimer?.cancel();
      _registrationRetryTimer = null;
    } catch (_) {
      _scheduleRegistrationRetry('carrier_pending');
    }
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
    final sessionKey = '$kind|$token';
    if (_registeredThisSession.contains(sessionKey)) return;

    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : 'android';

    try {
      await api.postFcmRegister(token: token, platform: platform);
      await prefs.setString(key, token);
      _registeredThisSession.add(sessionKey);
      _registrationRetryTimer?.cancel();
      _registrationRetryTimer = null;
    } catch (_) {
      _scheduleRegistrationRetry(kind);
    }
  }

  Future<void> unregisterCurrentDevice() async {
    _registrationRetryTimer?.cancel();
    _registrationRetryTimer = null;
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
    _registeredThisSession.clear();

    try {
      await _fm.deleteToken();
    } catch (_) {}
  }

  Future<void> _clearRegistrationCache(SharedPreferences prefs) async {
    await prefs.remove('fcm_registered_token_client');
    await prefs.remove('fcm_registered_token_carrier');
    await prefs.remove('fcm_registered_token_carrier_pending');
  }
}
