/*
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/router/app_router.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId = 'orthodox_taxi_main';
  static const _channelName = 'Orthodox Taxi';
  static const _channelDesc = 'Trip updates, promos, and alerts';

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();
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
      _channelId, _channelName,
      description: _channelDesc, importance: Importance.max,
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
        _channelId, _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_stat_taxi',
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true, presentBadge: true, presentSound: true,
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
    final title = notif?.title ?? (msg.data['title']?.toString() ?? 'Update');
    final body  = notif?.body  ?? (msg.data['body']?.toString()  ?? '');
    await show(title: title, body: body, data: msg.data);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundTap(NotificationResponse resp) {
    final payload = resp.payload;
    if (payload?.isEmpty ?? true) return;
    NotificationService._()._handleTapPayload(payload!);
  }

  factory NotificationService() => instance;

  void _handleTapPayload(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final route = data['route']?.toString();
      if (route != null && route.isNotEmpty) {
       */
/* AppRouterNav.pushFromOutside(route);*//*

      }
    } catch (e) {
      if (kDebugMode) print('Tap payload parse error: $e');
    }
  }
}
*/
