import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/app_design.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/widgets/common/app_bottom_nav.dart';
import '../../../data/services/logout_service.dart';

/// Нижняя навигация перевозчика.
///
/// Архитектура сохранена (три ветки `StatefulShellRoute.indexedStack`),
/// оформление приведено к общему [AppBottomNav].
class BottomCarrierTabBar extends StatelessWidget {
  const BottomCarrierTabBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<AppNavItem> _items = [
    AppNavItem(
      label: 'Главная',
      iconAsset: AppIcons.home,
      fallbackIcon: Icons.home_outlined,
    ),
    AppNavItem(
      label: 'Заказы',
      iconAsset: AppIcons.history,
      fallbackIcon: Icons.receipt_long_outlined,
    ),
    AppNavItem(
      label: 'Профиль',
      iconAsset: AppIcons.profile,
      fallbackIcon: Icons.person_outline_rounded,
    ),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Выйти из аккаунта?',
      message: 'Вы сможете снова войти по номеру телефона и паролю.',
      confirmLabel: 'Выйти',
      cancelLabel: 'Остаться',
      danger: true,
      icon: Icons.logout_rounded,
    );

    if (!confirmed || !context.mounted) return;

    await const LogoutService().logout();
    if (!context.mounted) return;
    context.go('/select_role');
  }

  @override
  Widget build(BuildContext context) {
    final showHomeLogout = navigationShell.currentIndex == 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          if (showHomeLogout)
            Positioned(
              top: MediaQuery.viewPaddingOf(context).top + 12,
              right: 14,
              child: Material(
                color: Colors.white.withValues(alpha: 0.94),
                elevation: 3,
                shadowColor: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _logout(context),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 20,
                          color: Color(0xFFD92D20),
                        ),
                        SizedBox(width: 7),
                        Text(
                          'Выйти',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD92D20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        items: _items,
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
