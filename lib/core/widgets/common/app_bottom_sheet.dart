import 'package:flutter/material.dart';

import '../../design/app_design.dart';

/// Общий каркас bottom sheet.
///
/// Гарантирует:
/// * скругление верхних углов 28 px;
/// * drag handle;
/// * безопасные отступы снизу;
/// * прокрутку содержимого;
/// * корректную работу с клавиатурой (`viewInsets.bottom`);
/// * ограничение максимальной высоты (по умолчанию 90% экрана);
/// * отсутствие overflow при любом размере экрана.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.footer,
    this.maxHeightFactor = 0.9,
    this.showHandle = true,
    this.showCloseButton = true,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  });

  final Widget child;
  final String? title;
  final String? subtitle;

  /// Закреплённая нижняя область (обычно основная кнопка).
  final Widget? footer;
  final double maxHeightFactor;
  final bool showHandle;
  final bool showCloseButton;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final safeBottom = media.viewPadding.bottom;
    final maxHeight = media.size.height * maxHeightFactor;

    return Padding(
      // Поднимаем лист над клавиатурой целиком.
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.sheetTop,
            boxShadow: AppShadows.sheet,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showHandle) const _DragHandle(),
              if (title != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding.left,
                    showHandle ? 0 : AppSpacing.lg,
                    showCloseButton ? AppSpacing.xs : padding.right,
                    AppSpacing.md,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title!, style: AppTypography.sectionTitle),
                            if (subtitle != null && subtitle!.isNotEmpty) ...[
                              AppSpacing.gapXxs,
                              Text(subtitle!, style: AppTypography.caption),
                            ],
                          ],
                        ),
                      ),
                      if (showCloseButton)
                        Semantics(
                          button: true,
                          label: 'Закрыть',
                          child: InkWell(
                            onTap: () => Navigator.of(context).maybePop(),
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
                        ),
                    ],
                  ),
                ),
              Flexible(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: padding.left,
                    right: padding.right,
                    top: title == null ? AppSpacing.xs : 0,
                    bottom: footer == null
                        ? AppSpacing.lg + safeBottom
                        : AppSpacing.md,
                  ),
                  child: child,
                ),
              ),
              if (footer != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding.left,
                    AppSpacing.xs,
                    padding.right,
                    AppSpacing.md + safeBottom,
                  ),
                  child: footer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderStrong,
          borderRadius: AppRadius.allFull,
        ),
      ),
    );
  }
}

/// Открывает [AppBottomSheet] с одинаковыми настройками во всём приложении.
///
/// `isScrollControlled: true` и `useSafeArea: true` обязательны, иначе лист
/// не поднимается над клавиатурой и заходит под вырез экрана.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: AppColors.transparent,
    barrierColor: AppColors.scrim,
    elevation: 0,
    builder: (sheetContext) => GestureDetector(
      onTap: () => FocusScope.of(sheetContext).unfocus(),
      child: builder(sheetContext),
    ),
  );
}
