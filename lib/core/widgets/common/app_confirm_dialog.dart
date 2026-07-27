import 'package:flutter/material.dart';

import '../../design/app_design.dart';
import '../buttons/app_buttons.dart';

/// Диалог подтверждения действия.
///
/// Возвращает `true`, если пользователь подтвердил.
/// Используется перед выходом из аккаунта, удалением точки маршрута
/// и отменой заказа.
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmLabel = 'Подтвердить',
    this.cancelLabel = 'Отмена',
    this.danger = false,
    this.icon,
  });

  final String title;
  final String? message;
  final String confirmLabel;
  final String cancelLabel;

  /// Опасное действие — красная кнопка подтверждения.
  final bool danger;
  final IconData? icon;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Подтвердить',
    String cancelLabel = 'Отмена',
    bool danger = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.scrim,
      builder: (_) => AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        danger: danger,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedIcon =
        icon ?? (danger ? Icons.warning_amber_rounded : Icons.help_outline);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: danger ? AppColors.errorSoft : AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  resolvedIcon,
                  size: 24,
                  color: danger ? AppColors.error : AppColors.primary,
                ),
              ),
            ),
            AppSpacing.gapMd,
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.cardTitle,
            ),
            if (message != null && message!.isNotEmpty) ...[
              AppSpacing.gapXs,
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTypography.caption,
              ),
            ],
            AppSpacing.gapLg,
            AppPrimaryButton(
              label: confirmLabel,
              danger: danger,
              size: AppButtonSize.medium,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            AppSpacing.gapXs,
            AppSecondaryButton(
              label: cancelLabel,
              size: AppButtonSize.medium,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
