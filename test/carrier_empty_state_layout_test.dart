import 'package:dogo/features/carrier_module/home/view/widgets/carrier_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(Size size) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: CarrierEmptyState(
            greeting: 'Добрый день, Азамат',
            onLeaveLine: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('Экран ожидания заказов', () {
    const sizes = <Size>[
      Size(320, 568),
      Size(360, 640),
      Size(390, 844),
      Size(430, 932),
    ];

    for (final size in sizes) {
      testWidgets('помещается целиком — ${size.width.toInt()}x'
          '${size.height.toInt()}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_harness(size));
        await tester.pump();

        expect(tester.takeException(), isNull);

        // Кнопка и заголовок обязаны оставаться в пределах экрана: раньше
        // фиксированный отступ 260px уводил их за нижнюю границу.
        final button = tester.getRect(find.text('Выйти с линии'));
        expect(button.bottom, lessThanOrEqualTo(size.height));
        expect(find.text('Пока нет активных\nзаказов'), findsOneWidget);
      });
    }

    testWidgets('содержимое не срезается при оттягивании обновления', (
      tester,
    ) async {
      const size = Size(360, 640);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var refreshed = false;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: size),
          child: MaterialApp(
            home: Scaffold(
              body: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async => refreshed = true,
                  child: CarrierEmptyState(
                    greeting: 'Добрый день, Азамат',
                    onLeaveLine: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.fling(
        find.text('Пока нет активных\nзаказов'),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(refreshed, isTrue);
      expect(tester.takeException(), isNull);
      expect(find.text('Выйти с линии'), findsOneWidget);
    });
  });
}
