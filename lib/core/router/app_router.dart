import 'package:dogo/features/auth_module/register/view/carrier_register_screen.dart';
import 'package:dogo/features/auth_module/login/login_screen.dart';
import 'package:dogo/features/auth_module/register/view/client_register_screens.dart';
import 'package:dogo/features/auth_module/register/view/components/selfie_capture_screen.dart';
import 'package:dogo/features/auth_module/register/view/components/selfie_waiting_screen.dart';
import 'package:dogo/features/auth_module/select_role/select_role_screen.dart';
import 'package:dogo/features/main_module/amanat/amanat_screen.dart';
import 'package:dogo/features/main_module/history/view/components/history_detail_data.dart';
import 'package:dogo/features/main_module/history/view/history_screen.dart';
import 'package:dogo/features/main_module/map/view/map_screen.dart';
import 'package:dogo/features/main_module/profile/view/profile_screen.dart';
import 'package:dogo/features/auth_module/splash/second_splash_screen.dart';
import 'package:dogo/features/auth_module/register/view/privacy_policy_screen.dart';

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
import '../../features/main_module/payments/view/finik_payment_screen.dart';

final class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  static const _transitionIn = Duration(milliseconds: 280);
  static const _transitionOut = Duration(milliseconds: 260);
  static const _curve = Curves.easeOutCubic;

  static CustomTransitionPage<T> _page<T>({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: _transitionIn,
      reverseTransitionDuration: _transitionOut,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final primary = animation.drive(
          Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: _curve)),
        );

        final secondary = secondaryAnimation.drive(
          Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.12, 0.0),
          ).chain(CurveTween(curve: _curve)),
        );

        return SlideTransition(
          position: primary,
          child: SlideTransition(position: secondary, child: child),
        );
      },
    );
  }

  static Page<dynamic> _build(GoRouterState state, Widget child) =>
      _page(state: state, child: child);

  static final GoRouter router = GoRouter(
    navigatorKey: _navKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _build(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/second_splash',
        pageBuilder: (context, state) =>
            _build(state, const SecondSplashScreen()),
      ),
      GoRoute(
        path: '/select_role',
        pageBuilder: (context, state) =>
            _build(state, const RoleSelectScreen()),
      ),
      GoRoute(
        path: '/select-specialist-type',
        pageBuilder: (context, state) =>
            _build(state, const SpecialistTypeSelectScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _build(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register-client',
        pageBuilder: (context, state) =>
            _build(state, const ClientRegisterScreen()),
      ),
      GoRoute(
        path: '/register-carrier',
        pageBuilder: (context, state) =>
            _build(state, const CarrierRegisterScreen()),
      ),
      GoRoute(
        path: '/register/confirm',
        pageBuilder: (context, state) =>
            _build(state, const ConfirmSelfieScreen()),
      ),
      GoRoute(
        path: '/register/confirm/whatsapp',
        pageBuilder: (context, state) =>
            _build(state, const ConfirmWhatsappCodeScreen()),
      ),
      GoRoute(
        path: '/history/detail',
        pageBuilder: (context, state) {
          final id = state.extra as int;
          return _build(state, HistoryDetailsScreen(shipmentId: id));
        },
      ),
      GoRoute(
        path: '/history-carrier/detail',
        pageBuilder: (context, state) {
          final id = state.extra as int;
          return _build(state, CarrierHistoryDetailsScreen(shipmentId: id));
        },
      ),
      GoRoute(
        path: '/profile/notifications',
        pageBuilder: (context, state) =>
            _build(state, const ProfileNotificationsScreen()),
      ),
      GoRoute(
        path: '/profile/account',
        pageBuilder: (context, state) =>
            _build(state, const ProfileAccountScreen()),
      ),
      GoRoute(
        path: '/profile/balance-history',
        pageBuilder: (context, state) =>
            _build(state, const ProfileBalanceHistoryScreen()),
      ),
      GoRoute(
        path: '/profile/support',
        pageBuilder: (context, state) =>
            _build(state, const ProfileSupportScreen()),
      ),

      GoRoute(
        path: '/selfie-capture',
        pageBuilder: (context, state) => _build(state, SelfieCaptureScreen()),
      ),

      GoRoute(
        path: '/selfie-waiting',
        pageBuilder: (context, state) => _build(state, SelfieWaitingScreen()),
      ),
      GoRoute(
        path: '/profile/topup',
        pageBuilder: (context, state) =>
            _build(state, const BalanceTopUpScreen()),
      ),
      GoRoute(
        path: '/finik_pay',
        name: 'finik_pay',
        pageBuilder: (context, state) =>
            _build(state, const FinikPaymentScreen()),
      ),
      GoRoute(
        path: AmanatScreen.route,
        pageBuilder: (context, state) => _build(state, const AmanatScreen()),
      ),
      GoRoute(
        path: AmanatDetailScreen.route,
        pageBuilder: (context, state) {
          final campaignId = int.tryParse(
            state.uri.queryParameters['id'] ?? '',
          );
          if (campaignId == null) {
            return _build(state, const AmanatScreen());
          }
          return _build(state, AmanatDetailScreen(campaignId: campaignId));
        },
      ),
      GoRoute(
        path: '/privacy-policy',
        pageBuilder: (context, state) =>
            _build(state, const PrivacyPolicyScreen()),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) =>
            BottomTabBar(navigationShell: navShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    _build(state, const HomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                pageBuilder: (context, state) {
                  final service =
                      state.uri.queryParameters['service'] ?? 'delivery';
                  return _build(
                    state,
                    OrderMapScreen(
                      key: ValueKey('order-map-$service'),
                      serviceType: service,
                    ),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                pageBuilder: (context, state) =>
                    _build(state, const HistoryScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) =>
                    _build(state, const ProfileScreen()),
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
              GoRoute(
                path: '/home-carrier',
                pageBuilder: (context, state) =>
                    _build(state, const CarrierHomeScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history-carrier',
                pageBuilder: (context, state) =>
                    _build(state, const CarrierHistoryScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile-carrier',
                pageBuilder: (context, state) =>
                    _build(state, const CarrierProfileScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
