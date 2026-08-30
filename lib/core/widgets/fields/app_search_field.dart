import 'package:flutter/material.dart';

import '../../design/app_design.dart';

/// Строка поиска. Используется над картой и в списках справочников.
///
/// Кнопка очистки появляется через [ValueListenableBuilder] по контроллеру,
/// а не через `setState` на каждый символ — экран с картой не перерисовывается
/// при вводе.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    this.hint = 'Поиск',
    this.onChanged,
    this.onCleared,
    this.focusNode,
    this.leading,
    this.autofocus = false,
    this.elevated = true,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onCleared;
  final FocusNode? focusNode;

  /// Например, кнопка «назад» слева от поля.
  final Widget? leading;
  final bool autofocus;

  /// Приподнятая карточка (над картой) или плоское поле (в списке).
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.border),
        boxShadow: elevated ? AppShadows.raised : AppShadows.none,
      ),
      padding: EdgeInsets.only(left: leading == null ? AppSpacing.sm : AppSpacing.xs),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            AppSpacing.hGapXxs,
          ] else ...[
            const Icon(
              Icons.search_rounded,
              size: 20,
              color: AppColors.textTertiary,
            ),
            AppSpacing.hGapXs,
          ],
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.primary,
              style: AppTypography.field,
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hint,
                hintStyle: AppTypography.fieldHint,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              if (value.text.isEmpty) {
                return const SizedBox(width: AppSpacing.sm);
              }
              return Semantics(
                button: true,
                label: 'Очистить поиск',
                child: InkWell(
                  onTap: () {
                    controller.clear();
                    onChanged?.call('');
                    onCleared?.call();
                  },
                  borderRadius: AppRadius.allFull,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
