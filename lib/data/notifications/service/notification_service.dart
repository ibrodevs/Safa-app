import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_router.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'dogo_main';
  static const _channelName = 'Safa';
  static const _channelDesc = 'Заказы и системные уведомления Safa';

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
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
    );

    await _fln
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _inited = true;

    // A foreground local notification can still be tapped after the app was
    // terminated. flutter_local_notifications exposes that launch separately
    // from FirebaseMessaging.getInitialMessage().
    final launch = await _fln.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if (launch?.didNotificationLaunchApp == true && payload?.isNotEmpty == true) {
      _handleTapPayload(payload!);
    }
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
        styleInformation: BigTextStyleInformation(body),
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
    final title =
        notif?.title ??
        (data['title']?.toString().isNotEmpty == true
            ? data['title'].toString()
            : 'Уведомление Safa');
    final body =
        notif?.body ??
        (data['body']?.toString().isNotEmpty == true
            ? data['body'].toString()
            : '');

    await show(title: title, body: body, data: data);
  }

  factory NotificationService() => instance;

  void _handleTapPayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      NotificationRouter.routeFromData(
        Map<String, dynamic>.from(decoded),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Tap payload parse error: $e');
      }
    }
  }
}
