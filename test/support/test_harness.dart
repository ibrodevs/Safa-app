import 'package:dogo/core/design/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Размеры экранов, на которых обязан работать интерфейс (ТЗ §20, §26).
const List<Size> kScreenSizes = <Size>[
  Size(320, 568), // iPhone SE 1-го поколения, бюджетные Android
  Size(360, 640), // самый распространённый Android
  Size(390, 844), // iPhone 14
  Size(430, 932), // iPhone Pro Max
  Size(600, 960), // маленький планшет
];

/// Системные масштабы текста, которые проверяются (ТЗ §22).
const List<double> kTextScales = <double>[1.0, 1.2, 1.4];

/// Оборачивает виджет в приложение с реальной темой проекта.
///
/// Тема обязательна: без неё компоненты рендерятся дефолтным Material-стилем,
/// и тест проверял бы не то, что видит пользователь.
Widget wrapWithApp(Widget child, {double textScale = 1.0}) {
  return MaterialApp(
    theme: AppTheme.light,
    debugShowCheckedModeBanner: false,
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: child,
    ),
  );
}

/// Устанавливает размер экрана для теста и сбрасывает его после завершения.
void setScreenSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

/// Прогоняет [body] на каждом размере из [sizes] и проверяет, что ни один
/// не даёт исключений и не переполняет вёрстку.
///
/// `RenderFlex overflowed by N pixels` в тестах попадает в `FlutterError`,
/// поэтому достаточно убедиться, что исключений не зафиксировано.
void testAcrossScreenSizes(
  String description,
  Future<void> Function(WidgetTester tester, Size size) body, {
  List<Size> sizes = kScreenSizes,
}) {
  for (final size in sizes) {
    testWidgets('$description — ${size.width.toInt()}x${size.height.toInt()}', (
      tester,
    ) async {
      setScreenSize(tester, size);
      await body(tester, size);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Ошибка вёрстки на ширине ${size.width.toInt()} px',
      );
    });
  }
}
