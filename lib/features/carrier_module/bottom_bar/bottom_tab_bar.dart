import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/app_design.dart';
import '../../../core/widgets/common/app_bottom_nav.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        items: _items,
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
      ),
    );
  }
}
