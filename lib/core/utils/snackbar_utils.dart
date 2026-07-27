import 'package:flutter/material.dart';

import '../design/app_design.dart';
import 'app_logger.dart';
import 'friendly_error.dart';

/// Всплывающие уведомления приложения.
///
/// Snackbar используется только для сообщений, не относящихся к конкретному
/// полю формы: ошибки полей выводятся под самими полями
/// (`AppTextField.errorText`), общие ошибки формы — через `AppFormError`.
///
/// Технический текст ошибки пользователю не показывается: он попадает
/// только в лог, а на экран уходит результат [friendlyErrorMessage].
class AppSnackBar {
  const AppSnackBar._();

  static void showError(
    BuildContext context, {
    dynamic error,
    StackTrace? stackTrace,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final displayMessage = message ?? friendlyErrorMessage(error);

    if (error != null) {
      AppLogger.e('UI Error: $displayMessage', error, stackTrace);
    } else {
      AppLogger.e('UI Error: $displayMessage');
    }

    _show(
      context,
      message: displayMessage,
      icon: Icons.error_outline_rounded,
      accent: AppColors.error,
      background: AppColors.errorSoft,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showSuccess(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_outline_rounded,
      accent: AppColors.success,
      background: AppColors.successSoft,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      accent: AppColors.info,
      background: AppColors.infoSoft,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Раздел ещё не реализован на backend.
  static void showSoon(BuildContext context) {
    showInfo(
      context,
      message: 'Раздел появится в одном из ближайших обновлений',
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color accent,
    required Color background,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.transparent,
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.allMd,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.raised,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              AppSpacing.hGapXs,
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxs + 2),
                      child: Text(message, style: AppTypography.caption),
                    ),
                    if (actionLabel != null && onAction != null)
                      Semantics(
                        button: true,
                        label: actionLabel,
                        child: InkWell(
                          onTap: () {
                            messenger.hideCurrentSnackBar();
                            onAction();
                          },
                          borderRadius: AppRadius.allSm,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: Text(
                              actionLabel,
                              style: AppTypography.caption.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
