import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yandex_maps_mapkit_lite/init.dart' as init;

import 'data/network/api_service.dart';
import 'features/auth_module/register/data/repo/auth_repo.dart';
import 'features/auth_module/register/provider/auth_provider.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await init.initMapkit(
    apiKey: 'de9b5506-7d81-40ae-8c6b-c4a34f2386a9',
  );

  final api = ApiService();
  final authRepo = AuthRepository(api);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepo),
        ),
      ],
      child: const DoGoApp(),
    ),
  );
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
