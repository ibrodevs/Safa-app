import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('android declares runtime notification permission and FCM channel', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
    expect(
      manifest,
      contains('com.google.firebase.messaging.default_notification_channel_id'),
    );
    expect(manifest, contains('dogo_main'));
  });

  test('push tokens are unregistered before auth is cleared', () {
    final logout = File(
      'lib/data/services/logout_service.dart',
    ).readAsStringSync();
    final push = File(
      'lib/data/notifications/service/push_service.dart',
    ).readAsStringSync();

    final unregisterIndex = logout.indexOf('unregisterCurrentDevice()');
    final resetIndex = logout.indexOf('resetAll()');
    expect(unregisterIndex, greaterThanOrEqualTo(0));
    expect(resetIndex, greaterThan(unregisterIndex));

    expect(push, contains("'fcm/unregister/'"));
    expect(push, contains("_fm.onTokenRefresh.listen"));
    expect(push, contains('_registerTokenOnServer(token: token, kind: kind)'));
    expect(push, contains("prefs.remove('fcm_registered_token_client')"));
    expect(push, contains("prefs.remove('fcm_registered_token_carrier')"));
  });

  test('foreground and tapped notifications use one role-aware router', () {
    final push = File(
      'lib/data/notifications/service/push_service.dart',
    ).readAsStringSync();
    final local = File(
      'lib/data/notifications/service/notification_service.dart',
    ).readAsStringSync();
    final router = File(
      'lib/data/notifications/service/notification_router.dart',
    ).readAsStringSync();

    expect(push, contains('NotificationRouter.routeFromData'));
    expect(local, contains('NotificationRouter.routeFromData'));
    expect(local, contains('getNotificationAppLaunchDetails'));
    expect(router, contains("app == 'client'"));
    expect(router, contains("app == 'carrier'"));
    expect(router, contains("'/history/detail'"));
    expect(router, contains("'/home-carrier'"));
  });

  test('silent pushes never render a foreground local notification', () {
    final push = File(
      'lib/data/notifications/service/push_service.dart',
    ).readAsStringSync();

    expect(push, contains("msg.data['silent']?.toString() == '1'"));
    expect(push, contains('NotificationService.instance.showFromMessage(msg)'));
  });

  test(
    'background Firebase initialization uses generated platform options',
    () {
      final bg = File(
        'lib/data/notifications/firebase_bg_handler.dart',
      ).readAsStringSync();

      expect(bg, contains('DefaultFirebaseOptions.currentPlatform'));
    },
  );

  test('iOS target has push entitlement for debug and production', () {
    final debug = File(
      'ios/Runner/RunnerDebug.entitlements',
    ).readAsStringSync();
    final release = File(
      'ios/Runner/RunnerRelease.entitlements',
    ).readAsStringSync();
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    expect(debug, contains('<key>aps-environment</key>'));
    expect(debug, contains('<string>development</string>'));
    expect(release, contains('<string>production</string>'));
    expect(project, contains('com.apple.Push'));
    expect(project, contains('CODE_SIGN_ENTITLEMENTS'));
  });

  test('token registration retries and refreshes when app resumes', () {
    final push = File(
      'lib/data/notifications/service/push_service.dart',
    ).readAsStringSync();
    final main = File('lib/main.dart').readAsStringSync();

    expect(push, contains('_readTokenWithRetry'));
    expect(push, contains('_scheduleRegistrationRetry'));
    expect(push, contains('refreshRegistration'));
    expect(push, isNot(contains("if (prefs.getString(key) == token) return;")));
    expect(main, contains('PushService.instance.refreshRegistration()'));
  });
}
