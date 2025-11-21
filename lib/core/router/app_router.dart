// lib/core/router/app_router.dart
import 'package:dogo/features/auth_module/register/view/client_register_screens.dart';
import 'package:dogo/features/auth_module/select_role/select_role_screen.dart';
import 'package:dogo/features/main_module/history/components/history_detail_data.dart';
import 'package:dogo/features/main_module/history/history_screen.dart';
import 'package:dogo/features/main_module/map/map_screen.dart';
import 'package:dogo/features/main_module/profile/profile_screen.dart';
import 'package:dogo/features/main_module/splash/second_splash_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth_module/register/view/components/confirm_selfie_screen.dart';
import '../../features/auth_module/register/view/components/confirm_whatsapp_code_screen.dart';
import '../../features/main_module/bottom_bar/bottom_tab_bar.dart';
import '../../features/main_module/home/home_screen.dart';
import '../../features/main_module/splash/splash_screen.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    navigatorKey: _navKey,
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/second_splash',
        builder: (_, __) => const SecondSplashScreen(),
      ),
      GoRoute(
        path: '/select_role',
        builder: (_, __) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const ClientRegisterStep1Screen(),
      ),
      GoRoute(
        path: '/register/id',
        builder: (_, __) => const ClientRegisterStep2Screen(),
      ),
      GoRoute(
        path: '/register/confirm',
        builder: (_, __) => const ConfirmSelfieScreen(),
      ),
      GoRoute(
        path: '/register/confirm/whatsapp',
        builder: (_, __) => const ConfirmWhatsappCodeScreen(),
      ),
      GoRoute(
        path: '/history/detail',
        builder: (_, state) =>
            HistoryDetailsScreen(data: state.extra as HistoryDetailsData),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) =>
            BottomTabBar(navigationShell: navShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/map', builder: (_, __) => const OrderMapScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (_, __) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
