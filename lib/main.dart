import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yandex_maps_mapkit/init.dart' as yandex_init;
import 'package:yandex_maps_mapkit/mapkit_factory.dart';
import 'core/map/safa_yandex_map.dart';
import 'core/design/app_theme.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';
import 'data/network/api_service.dart';
import 'data/notifications/firebase_bg_handler.dart';
import 'data/notifications/service/notification_service.dart';
import 'data/notifications/service/push_service.dart';
import 'features/auth_module/register/data/repo/auth_repo.dart';
import 'features/auth_module/register/provider/auth_provider.dart';
import 'features/main_module/map/data/repo/delivery_geo_repository.dart';
import 'features/main_module/map/provider/active_shipment_provider.dart';
import 'features/main_module/map/provider/delivery_address_provider.dart';
import 'features/main_module/map/provider/delivery_autocomplete_provider.dart';
import 'features/main_module/amanat/amanat_provider.dart';
import 'features/main_module/payments/data/repo/shipments_repository.dart';
import 'features/main_module/profile/data/repo/profile_repo.dart';
import 'features/main_module/profile/provider/profile_provider.dart';
import 'features/main_module/profile/provider/support_provider.dart';
import 'features/main_module/payments/data/repo/finik_payments_repository.dart';
import 'features/main_module/payments/provider/finik_payment_flow_provider.dart';

bool _firebaseReady = false;
bool _mapKitReady = false;

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  await firebaseMessagingBackgroundHandler(message);
}

Future<void> _safeConfigureOrientation() async {
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]).timeout(const Duration(seconds: 3));
  } catch (error, stackTrace) {
    debugPrint('Startup: orientation configuration failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _safeInitFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    FirebaseMessaging.onBackgroundMessage(_bgHandler);
    _firebaseReady = true;
    debugPrint('Startup: Firebase initialized');
  } catch (error, stackTrace) {
    debugPrint('Startup: Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _safeInitMapKit() async {
  if (!SafaMapKitConfig.isConfigured) {
    debugPrint('Startup: MapKit key is not configured');
    return;
  }

  try {
    await yandex_init.initMapkit(
      apiKey: SafaMapKitConfig.apiKey,
      locale: 'ru_RU',
    ).timeout(const Duration(seconds: 10));

    _mapKitReady = true;
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      mapkit.onStart();
    }
    debugPrint('Startup: MapKit initialized');
  } catch (error, stackTrace) {
    debugPrint('Startup: MapKit initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _safeInitServices() async {
  if (!_firebaseReady) return;

  try {
    await NotificationService.instance.init().timeout(
      const Duration(seconds: 5),
    );
  } catch (error, stackTrace) {
    debugPrint('Startup: notification service initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  try {
    await PushService.instance.init().timeout(const Duration(seconds: 5));
  } catch (error, stackTrace) {
    debugPrint('Startup: push service initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _safeRefreshPushRegistration() async {
  if (!_firebaseReady) return;

  try {
    await PushService.instance.refreshRegistration().timeout(
      const Duration(seconds: 5),
    );
  } catch (error, stackTrace) {
    debugPrint('Lifecycle: push registration refresh failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

Future<void> _initializeAfterFirstFrame() async {
  // None of these integrations are allowed to block the first Flutter frame.
  // App Review must always get a usable UI even if a third-party SDK is slow,
  // unavailable, or incompatible with a newly released iOS version.
  await _safeConfigureOrientation();
  await _safeInitFirebase();

  // Keep independent integrations isolated from each other. A MapKit failure
  // must not prevent notifications from initializing, and vice versa.
  unawaited(_safeInitServices());
  unawaited(_safeInitMapKit());
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final api = ApiService();
  final authRepo = AuthRepository(api);
  final geoRepo = DeliveryGeoRepository(api);
  final profileRepo = ProfileRepository(api);
  final shipRepo = ShipmentsRepository();

  // Render the application before initializing optional third-party services.
  // Previously MapKit and Firebase were awaited here; any startup failure left
  // iOS displaying the white launch screen indefinitely.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
        ChangeNotifierProvider(create: (_) => DeliveryAddressProvider(geoRepo)),
        ChangeNotifierProvider(
          create: (_) => DeliveryAutocompleteProvider(geoRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(repo: profileRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => SupportProvider(repo: profileRepo),
        ),
        ChangeNotifierProvider(
          create: (_) => ActiveShipmentProvider(repo: shipRepo),
        ),
        ChangeNotifierProvider(create: (_) => AmanatProvider()),
        ChangeNotifierProvider(
          create: (_) => FinikPaymentFlowProvider(
            shipmentsRepo: shipRepo,
            paymentsRepo: FinikPaymentsRepository(api: api),
          ),
        ),
      ],
      child: const DoGoApp(),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializeAfterFirstFrame());
  });
}

class DoGoApp extends StatefulWidget {
  const DoGoApp({super.key});

  @override
  State<DoGoApp> createState() => _DoGoAppState();
}

class _DoGoAppState extends State<DoGoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_safeRefreshPushRegistration());
      if (_mapKitReady) mapkit.onStart();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      if (_mapKitReady) mapkit.onStop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_mapKitReady) mapkit.onTerminate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      builder: (context, child) {
        // Ограничиваем системный масштаб текста: интерфейс проверен на
        // 1.0–1.4, выше плотные экраны (карта, карточки заказов)
        // перестают читаться.
        return MediaQuery.withClampedTextScaling(
          minScaleFactor: 1.0,
          maxScaleFactor: 1.4,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
