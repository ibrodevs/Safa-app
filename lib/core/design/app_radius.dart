import 'package:flutter/painting.dart';

/// Радиусы скругления.
///
/// * 12 px — маленькие элементы (чипы, бейджи, иконочные кнопки);
/// * 14 px — поля ввода и кнопки;
/// * 20 px — карточки;
/// * 28 px — bottom sheet;
/// * [full] — аватары и круглые action-кнопки.
class AppRadius {
  const AppRadius._();

  static const double xs = 10;
  static const double sm = 12;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double full = 999;

  static const BorderRadius allXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius allFull = BorderRadius.all(Radius.circular(full));

  /// Верхние углы bottom sheet.
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}
