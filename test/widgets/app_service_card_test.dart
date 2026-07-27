import 'package:dogo/core/widgets/app_widgets.dart';
import 'package:dogo/features/main_module/services/service_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_harness.dart';

void main() {
  Widget buildCard(ServiceConfig config, {VoidCallback? onTap}) {
    return wrapWithApp(
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AppServiceCard(
            title: config.title,
            description: config.shortDescription,
            icon: config.icon,
            accent: config.accent,
            accentSoft: config.accentSoft,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );
  }

  group('AppServiceCard', () {
    testWidgets('показывает название и описание сервиса', (tester) async {
      await tester.pumpWidget(buildCard(ServiceConfig.delivery));

      expect(find.text('Доставка'), findsOneWidget);
      expect(find.text('Быстрая доставка между двумя точками'), findsOneWidget);
    });

    testWidgets('вызывает onTap при нажатии', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        buildCard(ServiceConfig.cars, onTap: () => taps++),
      );

      await tester.tap(find.text('Тачки'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('доступна скринридеру как кнопка', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildCard(ServiceConfig.amanat));

      final semantics = tester.getSemantics(find.byType(AppServiceCard));
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.label, contains('Аманат'));

      handle.dispose();
    });

    testAcrossScreenSizes('не переполняется на всех ширинах', (
      tester,
      size,
    ) async {
      for (final config in ServiceConfig.all) {
        await tester.pumpWidget(buildCard(config));
        await tester.pump();
        expect(find.text(config.title), findsOneWidget);
      }
    });

    testWidgets('выдерживает системный масштаб текста 1.4', (tester) async {
      setScreenSize(tester, const Size(320, 568));

      await tester.pumpWidget(
        wrapWithApp(
          textScale: 1.4,
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: AppServiceCard(
                title: ServiceConfig.cars.title,
                description: ServiceConfig.cars.shortDescription,
                icon: ServiceConfig.cars.icon,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Тачки'), findsOneWidget);
    });
  });
}
