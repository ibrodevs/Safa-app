import 'package:dogo/core/design/app_design.dart';
import 'package:dogo/features/main_module/map/data/model/delivery_refs_models.dart';
import 'package:dogo/features/main_module/map/view/widgets/container_map_marker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_harness.dart';

void main() {
  const container = ContainerRef(
    id: 7,
    bazarId: 1,
    bazarName: 'Дордой',
    passageId: 4,
    passageNumber: '4',
    number: '125',
    title: 'Контейнер 125',
    isActive: true,
    lat: '42.936',
    lon: '74.623',
    uiLabel: '125',
    displayTitle: 'Дордой, контейнер 125',
  );

  Widget buildMarker({
    bool selected = false,
    bool showLabel = true,
    VoidCallback? onTap,
  }) {
    return wrapWithApp(
      Scaffold(
        body: Center(
          child: ContainerMapMarker(
            container: container,
            selected: selected,
            showLabel: showLabel,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  group('ContainerMapMarker', () {
    testWidgets('показывает номер контейнера', (tester) async {
      await tester.pumpWidget(buildMarker());
      expect(find.text('125'), findsOneWidget);
    });

    testWidgets('номер контейнера оптически центрируется по вертикали', (
      tester,
    ) async {
      await tester.pumpWidget(buildMarker());

      final transformFinder = find.ancestor(
        of: find.text('125'),
        matching: find.byType(Transform),
      );
      expect(transformFinder, findsOneWidget);

      final transform = tester.widget<Transform>(transformFinder);
      expect(
        transform.transform.getTranslation().y,
        ContainerMapMarker.labelVerticalOffset,
      );
    });

    testWidgets('область нажатия не меньше 44 px', (tester) async {
      await tester.pumpWidget(buildMarker(onTap: () {}));

      final size = tester.getSize(find.byType(ContainerMapMarker));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    });

    testWidgets('реагирует на нажатие', (tester) async {
      var taps = 0;
      await tester.pumpWidget(buildMarker(onTap: () => taps++));

      await tester.tap(find.byType(ContainerMapMarker));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('выбранный контейнер показывает номер акцентным текстом', (
      tester,
    ) async {
      await tester.pumpWidget(buildMarker(selected: true));
      await tester.pumpAndSettle();

      final label = tester.widget<Text>(find.text('125'));
      final style = label.style!;

      expect(style.color, AppColors.primary);
      expect(style.fontWeight, FontWeight.w800);
      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets('невыбранный контейнер показывает только номер без фона', (
      tester,
    ) async {
      await tester.pumpWidget(buildMarker());
      await tester.pumpAndSettle();

      final label = tester.widget<Text>(find.text('125'));
      final style = label.style!;

      expect(style.color, AppColors.textPrimary);
      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets('на малом масштабе подпись скрывается', (tester) async {
      await tester.pumpWidget(buildMarker(showLabel: false));
      expect(find.text('125'), findsNothing);
    });

    testWidgets('выбранный контейнер показывает подпись даже без масштаба', (
      tester,
    ) async {
      await tester.pumpWidget(buildMarker(showLabel: false, selected: true));
      expect(find.text('125'), findsOneWidget);
    });

    testWidgets('доступен скринридеру с номером и базаром', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildMarker(onTap: () {}));

      final semantics = tester.getSemantics(find.byType(ContainerMapMarker));
      expect(semantics.label, contains('Контейнер 125'));
      expect(semantics.label, contains('Дордой'));
      expect(semantics.flagsCollection.isButton, isTrue);

      handle.dispose();
    });
  });

  group('ContainerRef', () {
    test('возвращает базар, проход, номер и координаты', () {
      expect(container.bazarName, 'Дордой');
      expect(container.passageNumber, '4');
      expect(container.number, '125');
      expect(container.latValue, 42.936);
      expect(container.lonValue, 74.623);
    });

    test('координаты без значения не превращаются в нули', () {
      const broken = ContainerRef(
        id: 8,
        bazarId: 1,
        bazarName: 'Дордой',
        passageId: 4,
        passageNumber: '4',
        number: '126',
        title: '',
        isActive: true,
        lat: '',
        lon: '',
        uiLabel: '',
        displayTitle: '',
      );

      expect(broken.latValue, isNull);
      expect(broken.lonValue, isNull);
    });
  });
}
