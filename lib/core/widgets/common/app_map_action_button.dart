import 'package:flutter/material.dart';

import '../../design/app_design.dart';

/// Плавающая кнопка над картой: «назад», «моя геолокация», «контейнеры».
///
/// Область нажатия — 44×44 px. Один компонент вместо трёх разных
/// реализаций в `map_screen` и `map_picker_screen`.
class AppMapActionButton extends StatelessWidget {
  const AppMapActionButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onTap,
    this.loading = false,
    this.active = false,
    this.badgeColor,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final bool loading;

  /// Активное состояние — оранжевая подсветка.
  final bool active;

  /// Цветная точка-метка (например, зелёная для контейнеров).
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null && !loading,
      label: semanticLabel,
      child: Material(
        color: active ? AppColors.primary : AppColors.surface,
        borderRadius: AppRadius.allSm,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: loading ? null : onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: AppRadius.allSm,
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
              ),
              boxShadow: AppShadows.raised,
            ),
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: active ? AppColors.white : AppColors.primary,
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: active
                              ? AppColors.white
                              : AppColors.textPrimary,
                        ),
                        if (badgeColor != null)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: badgeColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.surface,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Компактный чип-индикатор над картой: «Контейнеры: 42».
class AppMapStatusChip extends StatelessWidget {
  const AppMapStatusChip({
    super.key,
    required this.label,
    this.loading = false,
    this.dotColor = AppColors.container,
    this.onTap,
  });

  final String label;
  final bool loading;
  final Color dotColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: label,
      child: Material(
        color: AppColors.surface,
        borderRadius: AppRadius.allSm,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: loading ? null : onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 36),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: AppRadius.allSm,
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.raised,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: dotColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                AppSpacing.hGapXs,
                Text(
                  label,
                  style: AppTypography.badge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
