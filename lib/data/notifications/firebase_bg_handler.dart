import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';

import '../../firebase_options.dart';
import 'service/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (message.data['silent']?.toString() == '1') return;

  try {
    await NotificationService.instance.init();
    if (message.notification == null) {
      await NotificationService.instance.showFromMessage(message);
    }
  } catch (_) {}
}
