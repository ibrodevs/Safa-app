import 'package:dogo/features/auth_module/register/view/carrier_register_screen.dart';
import 'package:dogo/features/auth_module/register/view/client_register_screens.dart';
import 'package:dogo/features/auth_module/register/view/components/selfie_capture_screen.dart';
import 'package:dogo/features/auth_module/register/view/components/selfie_waiting_screen.dart';
import 'package:dogo/features/auth_module/select_role/select_role_screen.dart';
import 'package:dogo/features/main_module/history/view/components/history_detail_data.dart';
import 'package:dogo/features/main_module/history/view/history_screen.dart';
import 'package:dogo/features/main_module/map/view/map_screen.dart';
import 'package:dogo/features/main_module/profile/view/profile_screen.dart';
import 'package:dogo/features/auth_module/splash/second_splash_screen.dart';
import 'package:dogo/features/main_module/type_cargo/view/cargo_type_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth_module/register/view/components/confirm_selfie_screen.dart';
import '../../features/auth_module/register/view/components/confirm_whatsapp_code_screen.dart';
import '../../features/carrier_module/bottom_bar/bottom_tab_bar.dart';
import '../../features/carrier_module/history/view/carrier_history_screen.dart';
import '../../features/carrier_module/history/view/components/carrier_history_detail_data.dart';
import '../../features/carrier_module/home/carrier_home_screen.dart';
import '../../features/carrier_module/profile/view/carrier_profile_screen.dart';
import '../../features/carrier_module/profile/view/components/balance_top_up_screen.dart';
import '../../features/main_module/bottom_bar/bottom_tab_bar.dart';
import '../../features/main_module/home/home_screen.dart';
import '../../features/auth_module/splash/splash_screen.dart';
import '../../features/main_module/profile/view/components/profile_account_screen.dart';
import '../../features/main_module/profile/view/components/profile_balance_history_screen.dart';
import '../../features/main_module/profile/view/components/profile_notifications_screen.dart';
import '../../features/main_module/profile/view/components/profile_support_screen.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  static CustomTransitionPage<T> _buildPage<T>({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final inAnimation = animation.drive(
          Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(
            CurveTween(curve: Curves.easeOutCubic),
          ),
        );

        final outAnimation = secondaryAnimation.drive(
          Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.15, 0.0),
          ).chain(
            CurveTween(curve: Curves.easeOutCubic),
          ),
        );

        return SlideTransition(
          position: inAnimation,
          child: SlideTransition(
            position: outAnimation,
            child: child,
          ),
        );
      },
    );
  }

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
        path: '/register-client',
        builder: (_, __) => const ClientRegisterScreen(),
      ),
      GoRoute(
        path: '/register-carrier',
        builder: (_, __) => const CarrierRegisterScreen(),
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
        builder: (context, state) {
          final id = state.extra as int;
          return HistoryDetailsScreen(shipmentId: id);
        },
      ),
      GoRoute(
        path: '/history-carrier/detail',
        builder: (context, state) {
          final id = state.extra as int;
          return CarrierHistoryDetailsScreen(shipmentId: id);
        },
      ),
      GoRoute(
        path: '/profile/notifications',
        builder: (_, __) => const ProfileNotificationsScreen(),
      ),
      GoRoute(
        path: '/profile/account',
        builder: (_, __) => const ProfileAccountScreen(),
      ),
      GoRoute(
        path: '/profile/balance-history',
        builder: (_, __) => const ProfileBalanceHistoryScreen(),
      ),
      GoRoute(
        path: '/profile/support',
        builder: (_, __) => const ProfileSupportScreen(),
      ),

      GoRoute(
        path: '/selfie-capture',
        builder: (_, state) => SelfieCaptureScreen(),
      ),
      GoRoute(
        path: '/selfie-capture',
        builder: (_, state) =>
            SelfieCaptureScreen(),
      ),
      GoRoute(
        path: '/type_cargo',
        builder: (_, state) =>
            CargoTypeScreen(),
      ),
      GoRoute(
        path: '/selfie-waiting',
        builder: (_, state) =>
            SelfieWaitingScreen(),
      ),
      GoRoute(
        path: '/profile/topup',
        builder: (_, __) => const BalanceTopUpScreen(),
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) =>
            BottomCarrierTabBar(navigationShell: navShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home-carrier', builder: (_, __) => const CarrierHomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history-carrier',
                builder: (_, __) => const CarrierHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile-carrier',
                builder: (_, __) => const CarrierProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
