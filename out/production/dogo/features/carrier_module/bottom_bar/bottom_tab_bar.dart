// lib/widgets/bottom_tab_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class BottomCarrierTabBar extends StatefulWidget {
  const BottomCarrierTabBar({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<BottomCarrierTabBar> createState() => _BottomCarrierTabBarState();
}

class _BottomCarrierTabBarState extends State<BottomCarrierTabBar> {
  static const _accent = Color(0xFFE67E22);
  static const _bg      = Color(0xFFF7F8FA);
  static const _border  = Color(0xFFE9EDF2);
  static const _grey    = Color(0xFFB9C0C8);

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final idx = widget.navigationShell.currentIndex;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: _bg,
          border: Border(top: BorderSide(color: _border, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: _bg,
            elevation: 0,
            currentIndex: idx,
            onTap: _onTap,
            showUnselectedLabels: true,
            selectedItemColor: _accent,
            unselectedItemColor: _grey,
            selectedIconTheme: const IconThemeData(size: 26),
            unselectedIconTheme: const IconThemeData(size: 24),
            selectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            items: const [
              BottomNavigationBarItem(
                icon: _SvgNavIcon('assets/icons/ic_home.svg', color: _grey),
                activeIcon: _SvgNavIcon('assets/icons/ic_home_grey.svg', color: _accent),
                label: 'Главное',
              ),
              BottomNavigationBarItem(
                icon: _SvgNavIcon('assets/icons/ic_history.svg', color: _grey),
                activeIcon: _SvgNavIcon('assets/icons/ic_history.svg', color: _accent),
                label: 'История',
              ),
              BottomNavigationBarItem(
                icon: _SvgNavIcon('assets/icons/ic_profile.svg', color: _grey),
                activeIcon: _SvgNavIcon('assets/icons/ic_profile.svg', color: _accent),
                label: 'Профиль',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SvgNavIcon extends StatelessWidget {
  const _SvgNavIcon(this.asset, {required this.color, this.size = 24});
  final String asset;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
