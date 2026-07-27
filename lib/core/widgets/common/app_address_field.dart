import 'package:flutter/material.dart';

import '../../design/app_design.dart';

/// Плитка адреса — кликабельное «поле», открывающее выбор точки.
///
/// Заменяет `map/view/widgets/input_tile.dart`, у которого была жёсткая
/// высота 52 px и `maxLines: 1`, из-за чего длинный адрес контейнера
/// просто исчезал. Здесь высота задана `minHeight`, а подпись выводится
/// второй строкой.
class AppAddressField extends StatelessWidget {
  const AppAddressField({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.onTap,
    this.icon = Icons.place_outlined,
    this.iconColor,
    this.filled = false,
    this.trailing,
  });

  /// Подпись роли: «Откуда», «Куда», «Остановка 1».
  final String label;

  /// Выбранное значение или подсказка, если ничего не выбрано.
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;
  final IconData icon;
  final Color? iconColor;

  /// Значение выбрано — плитка выглядит заполненной.
  final bool filled;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final accent = iconColor ?? AppColors.primary;

    return Semantics(
      button: onTap != null,
      label: '$label: $value',
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.allMd,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.allMd,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs + 2,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.allMd,
              border: Border.all(
                color: filled
                    ? accent.withValues(alpha: 0.35)
                    : AppColors.border,
              ),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: filled
                        ? accent.withValues(alpha: 0.12)
                        : AppColors.surfaceMuted,
                    borderRadius: AppRadius.allXs,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: filled ? accent : AppColors.textTertiary,
                  ),
                ),
                AppSpacing.hGapXs,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: AppTypography.label),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: filled
                              ? AppColors.textPrimary
                              : AppColors.textTertiary,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.captionMuted,
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  AppSpacing.hGapXxs,
                  trailing!,
                ] else if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
