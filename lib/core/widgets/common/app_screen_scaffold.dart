import 'package:flutter/material.dart';

import '../../design/app_design.dart';

/// Каркас обычного экрана.
///
/// Решает три повторяющиеся проблемы старых экранов:
/// 1. клавиатура — контент скроллится, кнопка не перекрывается,
///    тап вне поля снимает фокус;
/// 2. адаптивность — горизонтальные отступы зависят от ширины,
///    контент ограничен по максимальной ширине на больших экранах;
/// 3. одинаковый заголовок и кнопка «назад» на всех экранах.
class AppScreenScaffold extends StatelessWidget {
  const AppScreenScaffold({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.showBackButton = false,
    this.onBack,
    this.actions,
    this.footer,
    this.hideFooterWhenKeyboardVisible = false,
    this.scrollable = true,
    this.backgroundColor = AppColors.background,
    this.dismissKeyboardOnTap = true,
    this.topPadding = AppSpacing.md,
    this.bottomPadding = AppSpacing.xl,
    this.maxContentWidth = AppBreakpoints.maxContentWidth,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  /// Закреплённая нижняя область (основная кнопка экрана).
  final Widget? footer;

  /// Освобождает место для полей ввода, пока открыта клавиатура.
  ///
  /// Подходит для длинных форм: действие остаётся доступно через `done` на
  /// клавиатуре, а после её закрытия footer снова появляется.
  final bool hideFooterWhenKeyboardVisible;
  final bool scrollable;
  final Color backgroundColor;
  final bool dismissKeyboardOnTap;
  final double topPadding;
  final double bottomPadding;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final horizontal = AppResponsive.horizontalPadding(context);
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final effectiveFooter = hideFooterWhenKeyboardVisible && keyboardVisible
        ? null
        : footer;

    final header = (title == null && !showBackButton && actions == null)
        ? null
        : _Header(
            title: title,
            subtitle: subtitle,
            showBackButton: showBackButton,
            onBack: onBack,
            actions: actions,
            horizontalPadding: horizontal,
          );

    Widget content = child;

    if (scrollable) {
      content = SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          horizontal,
          header == null ? topPadding : 0,
          horizontal,
          bottomPadding + (effectiveFooter == null ? safeBottom : 0),
        ),
        child: content,
      );
    } else {
      content = Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: content,
      );
    }

    content = AppContentWidth(maxWidth: maxContentWidth, child: content);

    Widget body = Column(
      children: [
        if (header != null) header,
        Expanded(child: content),
        if (effectiveFooter != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontal,
              AppSpacing.sm,
              horizontal,
              AppSpacing.md + safeBottom,
            ),
            child: AppContentWidth(
              maxWidth: maxContentWidth,
              alignment: Alignment.center,
              child: effectiveFooter,
            ),
          ),
      ],
    );

    body = SafeArea(bottom: false, child: body);

    if (dismissKeyboardOnTap) {
      body = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      // resizeToAvoidBottomInset остаётся включённым: контент скроллится,
      // а footer поднимается вместе с клавиатурой.
      body: body,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.showBackButton,
    required this.onBack,
    required this.actions,
    required this.horizontalPadding,
  });

  final String? title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final compact = AppResponsive.useCompactTitle(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.xs,
        horizontalPadding,
        AppSpacing.md,
      ),
      child: AppContentWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (showBackButton) ...[
                  Semantics(
                    button: true,
                    label: 'Назад',
                    child: InkWell(
                      onTap: onBack ?? () => Navigator.of(context).maybePop(),
                      borderRadius: AppRadius.allFull,
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.hGapXxs,
                ],
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: compact
                          ? AppTypography.screenTitleCompact
                          : AppTypography.screenTitle,
                    ),
                  )
                else
                  const Spacer(),
                if (actions != null) ...[AppSpacing.hGapXs, ...actions!],
              ],
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              AppSpacing.gapXxs,
              Padding(
                padding: EdgeInsets.only(left: showBackButton ? 48 : 0),
                child: Text(subtitle!, style: AppTypography.bodySecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
