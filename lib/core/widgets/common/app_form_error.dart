import 'package:flutter/material.dart';

import '../../design/app_design.dart';
import '../../utils/friendly_error.dart';

/// Блок общей ошибки формы — показывается над основной кнопкой.
///
/// Ошибки конкретных полей выводятся под самими полями
/// (`AppTextField.errorText`), а сюда попадает только то, что не относится
/// к одному полю: «неверные данные», сетевая ошибка, ответ сервера.
class AppFormError extends StatelessWidget {
  const AppFormError({super.key, this.error, this.message});

  /// Произвольная ошибка — прогоняется через [friendlyErrorMessage].
  final Object? error;

  /// Готовый текст (имеет приоритет над [error]).
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text =
        message ?? (error == null ? null : friendlyErrorMessage(error));

    return AnimatedSize(
      duration: AppDurations.fast,
      alignment: Alignment.topCenter,
      child: (text == null || text.isEmpty)
          ? const SizedBox(width: double.infinity)
          : Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  borderRadius: AppRadius.allSm,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.24),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                    AppSpacing.hGapXs,
                    Expanded(
                      child: Text(
                        text,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
