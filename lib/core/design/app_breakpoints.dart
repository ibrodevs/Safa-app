import 'package:flutter/widgets.dart';

import 'app_spacing.dart';

/// Пороги адаптивности и производные от них величины.
///
/// Приложение должно корректно работать на ширинах
/// 320 / 360 / 375 / 390 / 412 / 430 / 480 / 600 px.
class AppBreakpoints {
  const AppBreakpoints._();

  /// До этой ширины экран считается маленьким (iPhone SE, бюджетные Android).
  static const double compact = 360;

  /// От этой ширины экран считается большим (Pro Max, планшеты).
  static const double expanded = 430;

  /// Максимальная ширина основного контента — формы не растягиваются
  /// бесконечно на больших экранах.
  static const double maxContentWidth = 560;
}

/// Помощник адаптивности. Всё завязано на реальную ширину, без
/// `Transform.scale` и без фиксированных ширин экрана.
class AppResponsive {
  const AppResponsive._();

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppBreakpoints.compact;

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppBreakpoints.expanded;

  /// Горизонтальный отступ контента: 12–16 px на узких экранах,
  /// 24 px на больших.
  static double horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 340) return AppSpacing.sm;
    if (width < AppBreakpoints.compact) return AppSpacing.md;
    if (width < AppBreakpoints.expanded) return AppSpacing.lg;
    return AppSpacing.xl;
  }

  /// Отступы контента экрана с учётом безопасной области снизу.
  static EdgeInsets screenPadding(
    BuildContext context, {
    double top = AppSpacing.md,
    double bottom = AppSpacing.xl,
  }) {
    final h = horizontalPadding(context);
    return EdgeInsets.fromLTRB(h, top, h, bottom);
  }

  /// Заголовок экрана уменьшается на самых узких экранах,
  /// чтобы не переносился в три строки.
  static bool useCompactTitle(BuildContext context) => isCompact(context);
}

/// Центрирует и ограничивает ширину контента на больших экранах.
///
/// На телефоне ведёт себя как обычный контейнер во всю ширину.
class AppContentWidth extends StatelessWidget {
  const AppContentWidth({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
