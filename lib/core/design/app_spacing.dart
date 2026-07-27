import 'package:flutter/widgets.dart';

/// Единая сетка отступов: 4 / 8 / 12 / 16 / 20 / 24 / 32.
///
/// Случайных значений (13, 17, 19, 27) в новом коде быть не должно.
class AppSpacing {
  const AppSpacing._();

  /// 4 px — минимальный.
  static const double xxs = 4;

  /// 8 px — маленький.
  static const double xs = 8;

  /// 12 px — средний.
  static const double sm = 12;

  /// 16 px — основной.
  static const double md = 16;

  /// 20 px — увеличенный.
  static const double lg = 20;

  /// 24 px — секционный.
  static const double xl = 24;

  /// 32 px — крупный.
  static const double xxl = 32;

  // --- Готовые отступы ---------------------------------------------------

  static const EdgeInsets allXs = EdgeInsets.all(xs);
  static const EdgeInsets allSm = EdgeInsets.all(sm);
  static const EdgeInsets allMd = EdgeInsets.all(md);
  static const EdgeInsets allLg = EdgeInsets.all(lg);

  // --- Вертикальные распорки ---------------------------------------------

  static const Widget gapXxs = SizedBox(height: xxs);
  static const Widget gapXs = SizedBox(height: xs);
  static const Widget gapSm = SizedBox(height: sm);
  static const Widget gapMd = SizedBox(height: md);
  static const Widget gapLg = SizedBox(height: lg);
  static const Widget gapXl = SizedBox(height: xl);
  static const Widget gapXxl = SizedBox(height: xxl);

  // --- Горизонтальные распорки -------------------------------------------

  static const Widget hGapXxs = SizedBox(width: xxs);
  static const Widget hGapXs = SizedBox(width: xs);
  static const Widget hGapSm = SizedBox(width: sm);
  static const Widget hGapMd = SizedBox(width: md);
  static const Widget hGapLg = SizedBox(width: lg);
}
