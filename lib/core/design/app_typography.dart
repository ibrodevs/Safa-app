import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Типографика приложения.
///
/// Используется единственное семейство [fontFamily] — `SFProText`, потому что
/// это единственный подключённый в `pubspec.yaml` шрифт с полным набором
/// начертаний (300…700). Раньше код ссылался на `Inter`, `SF Pro Display`
/// и `SF Pro`, которых в проекте нет, и Flutter молча падал на системный шрифт.
///
/// Максимальная насыщенность — `w700`: более тяжёлых начертаний в шрифте нет,
/// поэтому `w800`/`w900` синтезировать бессмысленно.
///
/// Все `height` — не меньше 1.15, чтобы текст не обрезался при системном
/// масштабе 1.4.
class AppTypography {
  const AppTypography._();

  static const String fontFamily = 'SFProText';

  /// Заголовок экрана — 28 px.
  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// Компактный заголовок экрана — 22 px (для узких экранов и app bar).
  static const TextStyle screenTitleCompact = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  /// Заголовок секции — 19 px.
  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 19,
    height: 1.3,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  /// Название карточки — 16 px.
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.35,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Основной текст — 15 px.
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Основной текст, вторичный цвет.
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// Вспомогательный текст — 13 px.
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  /// Слабый вспомогательный текст — 13 px.
  static const TextStyle captionMuted = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
  );

  /// Подпись статуса — 12 px.
  static const TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Текст основной кнопки — 16 px.
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  /// Текст поля ввода.
  static const TextStyle field = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Подсказка в поле ввода.
  static const TextStyle fieldHint = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.35,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  /// Подпись над полем ввода.
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
}
