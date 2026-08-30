import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:yandex_maps_mapkit_lite/init.dart' as yandex_init;
import 'package:yandex_maps_mapkit_lite/mapkit_factory.dart';
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
    await PushService.instance.init().timeout(const Duration(seconds: 5));
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  if (SafaMapKitConfig.isConfigured) {
    debugPrint('MAPKIT DEBUG: key=${SafaMapKitConfig.apiKey}');
    await yandex_init.initMapkit(
      apiKey: SafaMapKitConfig.apiKey,
      locale: 'ru_RU',
    );
    mapkit.onStart();
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_bgHandler);

  final api = ApiService();
  final authRepo = AuthRepository(api);
  final geoRepo = DeliveryGeoRepository(api);
  final profileRepo = ProfileRepository(api);
  final shipRepo = ShipmentsRepository();
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

  unawaited(_safeInitServices());
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
      unawaited(PushService.instance.refreshRegistration());
      if (SafaMapKitConfig.isConfigured) mapkit.onStart();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      if (SafaMapKitConfig.isConfigured) mapkit.onStop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (SafaMapKitConfig.isConfigured) mapkit.onTerminate();
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
