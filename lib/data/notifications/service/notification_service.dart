import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/router/app_router.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'dogo_main';
  static const _channelName = 'DoGo';
  static const _channelDesc = 'Delivery updates and alerts';

  final FlutterLocalNotificationsPlugin _fln =
  FlutterLocalNotificationsPlugin();
  bool _inited = false;

  Future<void> init() async {
    if (_inited) return;

    const android = AndroidInitializationSettings('ic_stat_taxi');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final init = InitializationSettings(android: android, iOS: ios);

    await _fln.initialize(
      init,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload?.isNotEmpty == true) {
          _handleTapPayload(payload!);
        }
      },
      onDidReceiveBackgroundNotificationResponse:
      NotificationService._onBackgroundTap,
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
    );

    await _fln
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _inited = true;
  }

  Future<void> show({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    int? id,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_stat_taxi',
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _fln.show(
      id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: data == null ? null : jsonEncode(data),
    );
  }

  Future<void> showFromMessage(RemoteMessage msg) async {
    final notif = msg.notification;
    final data = msg.data;
    final title = notif?.title ??
        (data['title']?.toString().isNotEmpty == true
            ? data['title'].toString()
            : 'Уведомление');
    final body = notif?.body ??
        (data['body']?.toString().isNotEmpty == true
            ? data['body'].toString()
            : '');

    await show(title: title, body: body, data: data);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundTap(NotificationResponse resp) {
    final payload = resp.payload;
    if (payload?.isEmpty ?? true) {
      return;
    }
    NotificationService._()._handleTapPayload(payload!);
  }

  factory NotificationService() => instance;

  void _handleTapPayload(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final route = _extractRoute(data);
      if (route != null && route.isNotEmpty) {
        AppRouter.router.go(route);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Tap payload parse error: $e');
      }
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
}
