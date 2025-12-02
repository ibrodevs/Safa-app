import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'data/network/api_service.dart';
import 'data/notifications/firebase_bg_handler.dart';
import 'data/notifications/service/notification_service.dart';
import 'data/notifications/service/push_service.dart';
import 'features/auth_module/register/data/repo/auth_repo.dart';
import 'features/auth_module/register/provider/auth_provider.dart';
import 'features/main_module/map/data/repo/delivery_geo_repository.dart';
import 'features/main_module/map/provider/delivery_address_provider.dart';
import 'features/main_module/map/provider/delivery_autocomplete_provider.dart';

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  await firebaseMessagingBackgroundHandler(message);
}

Future<void> _safeInitServices() async {
  try {
    await NotificationService.instance.init().timeout(
      const Duration(seconds: 5),
    );
  } catch (_) {}
  try {
    await PushService.instance.init().timeout(
      const Duration(seconds: 5),
    );
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_bgHandler);

  final api = ApiService();
  final authRepo = AuthRepository(api);
  final geoRepo = DeliveryGeoRepository(api);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => DeliveryAddressProvider(geoRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => DeliveryAutocompleteProvider(geoRepo),
        ),
      ],
      child: const DoGoApp(),
    ),
  );

  unawaited(_safeInitServices());
}

class DoGoApp extends StatelessWidget {
  const DoGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
