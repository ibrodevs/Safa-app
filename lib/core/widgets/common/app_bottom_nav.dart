import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design/app_design.dart';

/// Элемент нижней навигации.
@immutable
class AppNavItem {
  const AppNavItem({
    required this.label,
    required this.iconAsset,
    this.fallbackIcon = Icons.circle_outlined,
  });

  final String label;
  final String iconAsset;

  /// Иконка, если SVG не загрузился.
  final IconData fallbackIcon;
}

/// Нижняя навигация приложения.
///
/// Единый стиль для клиентского шелла и шелла перевозчика. Раньше это были
/// два разных `BottomNavigationBar` с собственными цветами, а активная
/// иконка «Главное» использовала ассет `ic_home_grey.svg`, то есть иконки
/// активного и неактивного состояний были перепутаны.
///
/// Активная вкладка отмечена цветом, насыщенностью подписи и подложкой —
/// не одним лишь цветом. Высота панели минимальна, нижняя безопасная
/// область учитывается.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    assert(items.length <= 5, 'Больше пяти вкладок не поддерживается');

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavButton(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textTertiary;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allSm,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppDurations.normal,
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primarySoft
                      : AppColors.transparent,
                  borderRadius: AppRadius.allFull,
                ),
                child: SvgPicture.asset(
                  item.iconAsset,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  placeholderBuilder: (_) =>
                      Icon(item.fallbackIcon, size: 20, color: color),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.badge.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
