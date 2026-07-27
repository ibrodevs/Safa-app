/// Длительности анимаций: 150–250 ms, как требует дизайн-гайд.
///
/// Тяжёлых и длинных анимаций в приложении нет.
class AppDurations {
  const AppDurations._();

  /// 150 ms — нажатия, смена цвета, появление бейджа.
  static const Duration fast = Duration(milliseconds: 150);

  /// 200 ms — смена вкладки, раскрытие блока.
  static const Duration normal = Duration(milliseconds: 200);

  /// 250 ms — открытие bottom sheet, добавление/удаление точки маршрута.
  static const Duration slow = Duration(milliseconds: 250);
}
