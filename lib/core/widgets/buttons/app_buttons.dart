import 'package:flutter/material.dart';

import '../../design/app_design.dart';

/// Размеры кнопок.
enum AppButtonSize {
  /// 44 px — минимальная интерактивная область.
  small(44, 14),

  /// 52 px — обычная кнопка внутри карточек и листов.
  medium(52, 16),

  /// 56 px — главная кнопка экрана.
  large(56, 16);

  const AppButtonSize(this.height, this.fontSize);

  final double height;
  final double fontSize;
}

/// Основная (акцентная) кнопка.
///
/// Поддерживает обычное состояние, нажатие, загрузку, отключение и
/// состояние ошибки (`danger`).
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.size = AppButtonSize.large,
    this.icon,
    this.expand = true,
    this.danger = false,
    this.loadingLabel,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Показывает индикатор внутри кнопки и блокирует повторные нажатия.
  final bool loading;
  final bool enabled;
  final AppButtonSize size;
  final IconData? icon;

  /// Растягивать на всю доступную ширину.
  final bool expand;

  /// Опасное действие (удаление, выход) — красная кнопка.
  final bool danger;

  /// Текст, показываемый вместо [label] во время загрузки.
  final String? loadingLabel;

  bool get _interactive => enabled && !loading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final background = danger ? AppColors.error : AppColors.primary;

    final button = SizedBox(
      height: size.height,
      width: expand ? double.infinity : null,
      child: ElevatedButton(
        onPressed: _interactive ? onPressed : null,
        style:
            ElevatedButton.styleFrom(
              backgroundColor: background,
              foregroundColor: AppColors.textOnPrimary,
              disabledBackgroundColor: loading
                  ? background.withValues(alpha: 0.7)
                  : AppColors.surfaceMuted,
              disabledForegroundColor: loading
                  ? AppColors.textOnPrimary
                  : AppColors.textTertiary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.allMd,
              ),
            ).copyWith(
              overlayColor: WidgetStatePropertyAll(
                AppColors.white.withValues(alpha: 0.12),
              ),
            ),
        child: _AppButtonContent(
          label: loading ? (loadingLabel ?? label) : label,
          icon: icon,
          loading: loading,
          fontSize: size.fontSize,
          color: AppColors.textOnPrimary,
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _interactive,
      label: label,
      child: ExcludeSemantics(child: button),
    );
  }
}

/// Второстепенная кнопка: белый фон, серая граница.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.enabled = true,
    this.size = AppButtonSize.medium,
    this.icon,
    this.expand = true,
    this.accent = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool enabled;
  final AppButtonSize size;
  final IconData? icon;
  final bool expand;

  /// Оранжевая рамка и текст — для «+ Добавить остановку» и подобных.
  final bool accent;

  /// Красная рамка и текст — для отмены заказа и выхода.
  final bool danger;

  bool get _interactive => enabled && !loading && onPressed != null;

  @override
  Widget build(BuildContext context) {
    final Color foreground = danger
        ? AppColors.error
        : accent
        ? AppColors.primary
        : AppColors.textPrimary;

    final Color borderColor = danger
        ? AppColors.error.withValues(alpha: 0.4)
        : accent
        ? AppColors.primary.withValues(alpha: 0.4)
        : AppColors.border;

    final button = SizedBox(
      height: size.height,
      width: expand ? double.infinity : null,
      child: OutlinedButton(
        onPressed: _interactive ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          backgroundColor: accent ? AppColors.primarySoft : AppColors.surface,
          disabledForegroundColor: AppColors.textTertiary,
          side: BorderSide(
            color: _interactive ? borderColor : AppColors.border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        ),
        child: _AppButtonContent(
          label: label,
          icon: icon,
          loading: loading,
          fontSize: size.fontSize,
          color: _interactive ? foreground : AppColors.textTertiary,
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _interactive,
      label: label,
      child: ExcludeSemantics(child: button),
    );
  }
}

/// Текстовая кнопка-ссылка. Область нажатия — не меньше 44 px.
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.enabled = true,
    this.danger = false,
    this.muted = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool danger;

  /// Приглушённый серый вариант («Отменить регистрацию»).
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final interactive = enabled && onPressed != null;

    final Color color = !interactive
        ? AppColors.textTertiary
        : danger
        ? AppColors.error
        : muted
        ? AppColors.textSecondary
        : AppColors.primary;

    return TextButton(
      onPressed: interactive ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTypography.body.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Круглая или квадратная иконочная кнопка с областью нажатия 44 px.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.background = AppColors.surface,
    this.foreground = AppColors.textPrimary,
    this.circular = true,
    this.bordered = true,
    this.badge = false,
    this.size = 44,
  });

  final IconData icon;

  /// Обязателен: без него кнопка не читается скринридером.
  final String semanticLabel;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final bool circular;
  final bool bordered;

  /// Точка-индикатор в правом верхнем углу (непрочитанные уведомления).
  final bool badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = circular ? AppRadius.allFull : AppRadius.allSm;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: Material(
        color: background,
        borderRadius: radius,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: bordered ? Border.all(color: AppColors.border) : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 20, color: foreground),
                if (badge)
                  Positioned(
                    top: size * 0.22,
                    right: size * 0.22,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
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

class _AppButtonContent extends StatelessWidget {
  const _AppButtonContent({
    required this.label,
    required this.icon,
    required this.loading,
    required this.fontSize,
    required this.color,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTypography.button.copyWith(fontSize: fontSize, color: color),
      ),
    );

    if (loading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          ),
          AppSpacing.hGapSm,
          text,
        ],
      );
    }

    if (icon == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [text],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: color),
        AppSpacing.hGapXs,
        text,
      ],
    );
  }
}
