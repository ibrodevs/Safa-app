import 'package:flutter/material.dart';

import '../../design/app_design.dart';

/// Тон бейджа. Цвет никогда не единственный носитель смысла —
/// текст показывается всегда, плюс опциональная иконка.
enum AppBadgeTone { neutral, primary, success, warning, error, info }

/// Компактный бейдж статуса.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
    this.icon,
    this.dense = false,
  });

  final String label;
  final AppBadgeTone tone;
  final IconData? icon;

  /// Уменьшенный вариант для карточек с плотной вёрсткой.
  final bool dense;

  Color get _foreground {
    switch (tone) {
      case AppBadgeTone.primary:
        return AppColors.primaryPressed;
      case AppBadgeTone.success:
        return AppColors.success;
      case AppBadgeTone.warning:
        return AppColors.warning;
      case AppBadgeTone.error:
        return AppColors.error;
      case AppBadgeTone.info:
        return AppColors.info;
      case AppBadgeTone.neutral:
        return AppColors.textSecondary;
    }
  }

  Color get _background {
    switch (tone) {
      case AppBadgeTone.primary:
        return AppColors.primarySoft;
      case AppBadgeTone.success:
        return AppColors.successSoft;
      case AppBadgeTone.warning:
        return AppColors.warningSoft;
      case AppBadgeTone.error:
        return AppColors.errorSoft;
      case AppBadgeTone.info:
        return AppColors.infoSoft;
      case AppBadgeTone.neutral:
        return AppColors.neutralSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? AppSpacing.xs : AppSpacing.sm - 2,
          vertical: dense ? AppSpacing.xxs : AppSpacing.xxs + 2,
        ),
        decoration: BoxDecoration(
          color: _background,
          borderRadius: AppRadius.allSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: _foreground),
              AppSpacing.hGapXxs,
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.badge.copyWith(color: _foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
