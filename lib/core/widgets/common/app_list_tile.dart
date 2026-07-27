import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../design/app_design.dart';

/// Строка списка настроек/профиля. Высота — не меньше 56 px.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconAsset,
    this.trailing,
    this.onTap,
    this.showChevron = true,
    this.danger = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Путь к SVG (см. [AppIcons]). Имеет приоритет над [icon].
  final String? iconAsset;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  /// Опасное действие (выход, удаление аккаунта) — красный текст и иконка.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Color accent = danger ? AppColors.error : AppColors.primary;
    final Color titleColor = danger ? AppColors.error : AppColors.textPrimary;

    return Semantics(
      button: onTap != null,
      label: title,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allMd,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                if (iconAsset != null || icon != null) ...[
                  _Leading(
                    icon: icon,
                    iconAsset: iconAsset,
                    color: accent,
                    soft: danger ? AppColors.errorSoft : AppColors.primarySoft,
                  ),
                  AppSpacing.hGapSm,
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: AppTypography.cardTitle.copyWith(
                          color: titleColor,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: AppTypography.caption),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  AppSpacing.hGapXs,
                  trailing!,
                ] else if (showChevron && onTap != null) ...[
                  AppSpacing.hGapXs,
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.textTertiary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading({
    required this.icon,
    required this.iconAsset,
    required this.color,
    required this.soft,
  });

  final IconData? icon;
  final String? iconAsset;
  final Color color;
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: soft, borderRadius: AppRadius.allXs),
      alignment: Alignment.center,
      child: iconAsset != null
          ? SvgPicture.asset(
              iconAsset!,
              width: 18,
              height: 18,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              placeholderBuilder: (_) =>
                  Icon(Icons.circle_outlined, size: 18, color: color),
            )
          : Icon(icon, size: 18, color: color),
    );
  }
}

/// Группа строк с разделителями, обёрнутая в карточку.
class AppTileGroup extends StatelessWidget {
  const AppTileGroup({super.key, required this.children, this.title});

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xxs),
            child: Text(
              title!.toUpperCase(),
              style: AppTypography.label.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 0.6,
              ),
            ),
          ),
          AppSpacing.gapXs,
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.allLg,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 64, right: AppSpacing.md),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
