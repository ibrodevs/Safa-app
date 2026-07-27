import 'package:flutter/painting.dart';

/// Мягкие, едва заметные тени. Тяжёлых тёмных теней в приложении нет.
///
/// Для большинства карточек достаточно светлой границы
/// (`AppColors.border`) и [card].
class AppShadows {
  const AppShadows._();

  /// Обычная карточка: почти невидимая тень поверх светлой границы.
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A101828), blurRadius: 12, offset: Offset(0, 2)),
  ];

  /// Приподнятый элемент: плавающая кнопка, плитка адреса над картой.
  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x0F101828), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A101828), blurRadius: 4, offset: Offset(0, 1)),
  ];

  /// Bottom sheet и нижние панели над картой.
  static const List<BoxShadow> sheet = [
    BoxShadow(color: Color(0x1A101828), blurRadius: 28, offset: Offset(0, -4)),
  ];

  /// Без тени.
  static const List<BoxShadow> none = <BoxShadow>[];
}
