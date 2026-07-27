import 'package:flutter/painting.dart';

/// Единая палитра приложения.
///
/// Это единственный источник правды о цвете. `lib/core/utils/app_colors.dart`
/// реэкспортирует этот файл, поэтому старые импорты продолжают работать.
///
/// Оранжевый используется только для главных кнопок, активных элементов,
/// выбранных вкладок и важных маркеров — не как фон больших областей.
class AppColors {
  const AppColors._();

  // --- Бренд -------------------------------------------------------------
  /// Основной фирменный оранжевый.
  static const primary = Color(0xFFFF8A00);

  /// Нажатое / активное состояние основной кнопки.
  static const primaryPressed = Color(0xFFF57C00);

  /// Светлый фон акцентного элемента (бейджи, выбранные плитки).
  static const primarySoft = Color(0xFFFFF4E8);

  // --- Поверхности -------------------------------------------------------
  /// Основной фон приложения.
  static const background = Color(0xFFF6F7F9);

  /// Фон карточек и листов.
  static const surface = Color(0xFFFFFFFF);

  /// Приглушённая поверхность: поля ввода, неактивные плитки.
  static const surfaceMuted = Color(0xFFF2F4F7);

  // --- Текст -------------------------------------------------------------
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF667085);
  static const textTertiary = Color(0xFF98A2B3);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // --- Границы -----------------------------------------------------------
  static const border = Color(0xFFE4E7EC);
  static const borderStrong = Color(0xFFD0D5DD);

  // --- Семантика ---------------------------------------------------------
  static const success = Color(0xFF12B76A);
  static const successSoft = Color(0xFFE7F8F0);

  static const error = Color(0xFFF04438);
  static const errorSoft = Color(0xFFFEECEB);

  static const warning = Color(0xFFF79009);
  static const warningSoft = Color(0xFFFEF3E2);

  static const info = Color(0xFF2E90FA);
  static const infoSoft = Color(0xFFEAF3FE);

  static const neutralSoft = Color(0xFFF2F4F7);

  // --- Карта -------------------------------------------------------------
  /// Контейнеры на карте.
  static const container = Color(0xFF1E8E3E);

  /// Заливка полигона контейнера.
  static const containerFill = Color(0x291E8E3E);

  /// Линия маршрута.
  static const routeLine = Color(0xFF1D2939);

  /// Обводка линии маршрута.
  static const routeLineHalo = Color(0xFFFFFFFF);

  // --- Утилитарные -------------------------------------------------------
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const transparent = Color(0x00000000);

  /// Затемнение под модальными листами.
  static const scrim = Color(0x52101828);

  // --- Legacy-алиасы -----------------------------------------------------
  // Сохранены, чтобы не ломать ~40 файлов, которые уже импортируют AppColors.
  // Все указывают на новые токены палитры — старых «пяти оранжевых» больше нет.

  /// Устарело. Используйте [primary].
  static const accent = primary;

  /// Устарело. Используйте [primary].
  static const burntOrange = primaryPressed;

  /// Устарело. Используйте [primary].
  static const paywallAccent = primary;

  /// Устарело. Используйте [primary].
  static const buttonColor = primaryPressed;

  /// Устарело. Используйте [textSecondary].
  static const greyText = textSecondary;

  /// Устарело. Используйте [textTertiary].
  static const subtitleGrey = textTertiary;

  /// Устарело. Используйте [textTertiary].
  static const subtitleColor = textTertiary;

  /// Устарело. Используйте [textTertiary].
  static const grey = textTertiary;

  /// Устарело. Используйте [textSecondary].
  static const grey2 = textSecondary;

  /// Устарело. Используйте [borderStrong].
  static const grey3 = borderStrong;

  /// Устарело. Используйте [surfaceMuted].
  static const lightGrey = surfaceMuted;

  /// Устарело. Используйте [error].
  static const red = error;

  /// Устарело. Используйте [error].
  static const red2 = Color(0x80F04438);

  /// Устарело. Используйте [success].
  static const green = success;

  /// Устарело. Используйте [border].
  static const tileBorder = border;

  /// Устарело. Используйте [borderStrong].
  static const chev = borderStrong;

  /// Устарело. Используйте [border].
  static const chev2 = border;

  /// Устарело. Используйте [primarySoft].
  static const chev3 = primarySoft;

  /// Устарело. Используйте [primarySoft].
  static const org2 = primarySoft;

  /// Устарело. Используйте [textTertiary].
  static const hintColor = textTertiary;

  /// Устарело. Используйте [textTertiary].
  static const cancelColor = textTertiary;

  /// Устарело. Используйте [AppShadows].
  static const boxShadow = Color(0x14101828);

  /// Устарело. Используйте [AppShadows].
  static const boxShadow2 = Color(0x0A101828);

  /// Устарело. Используйте [info].
  static const blue = info;

  /// Устарело. Используйте [info].
  static const deepPurple = info;
}
