import 'package:dogo/core/widgets/app_widgets.dart';
import 'package:dogo/features/main_module/map/data/model/delivery_point_model.dart';
import 'package:dogo/features/main_module/map/view/components/route_builder.dart';
import 'package:dogo/features/main_module/services/service_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_harness.dart';

void main() {
  const start = 'Дордой, вход 5';

  List<DeliveryPoint> stops(int count) => List.generate(
    count,
    (i) => DeliveryPoint(
      title: 'Остановка ${i + 1}',
      subtitle: 'Контейнер: ${100 + i} • Проход: ${i + 1}',
      lat: 42.9 + i * 0.001,
      lon: 74.6 + i * 0.001,
    ),
  );

  const destination = DeliveryPoint(
    title: 'Ошский базар',
    subtitle: 'Контейнер: 12 • Проход: 3',
    lat: 42.87,
    lon: 74.58,
  );

  Widget buildBuilder({
    required ServiceConfig config,
    List<DeliveryPoint> intermediate = const [],
    DeliveryPoint? destinationPoint = destination,
    void Function(int index)? onRemove,
    void Function(int oldIndex, int newIndex)? onReorder,
    VoidCallback? onAdd,
    void Function(int index)? onEditStop,
  }) {
    return wrapWithApp(
      Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: RouteBuilder(
            config: config,
            fromTitle: start,
            fromSubtitle: 'Контейнер: 125',
            fromIsSelected: true,
            destination: destinationPoint,
            intermediatePoints: intermediate,
            onEditFrom: () {},
            onEditDestination: () {},
            onEditIntermediate: onEditStop ?? (_) {},
            onAddIntermediate: onAdd ?? () {},
            onRemoveIntermediate: onRemove ?? (_) {},
            onReorderIntermediate: onReorder ?? (_, __) {},
          ),
        ),
      ),
    );
  }

  group('RouteBuilder — «Доставка»', () {
    testWidgets('показывает только начальную и конечную точки', (tester) async {
      await tester.pumpWidget(buildBuilder(config: ServiceConfig.delivery));

      expect(find.text('Откуда'), findsOneWidget);
      expect(find.text('Куда'), findsOneWidget);
      expect(find.text(start), findsOneWidget);
      expect(find.text('Ошский базар'), findsOneWidget);
    });

    testWidgets('не предлагает добавить остановку', (tester) async {
      await tester.pumpWidget(buildBuilder(config: ServiceConfig.delivery));

      expect(find.text('+ Добавить остановку'), findsNothing);
    });
  });

  group('RouteBuilder — «Тачки»', () {
    testWidgets('показывает несколько нумерованных остановок', (tester) async {
      await tester.pumpWidget(
        buildBuilder(config: ServiceConfig.cars, intermediate: stops(3)),
      );

      expect(find.text('Остановка 1'), findsWidgets);
      expect(find.text('Остановка 2'), findsWidgets);
      expect(find.text('Остановка 3'), findsWidgets);
      expect(find.text('Откуда'), findsOneWidget);
      expect(find.text('Куда'), findsOneWidget);
    });

    testWidgets('предлагает добавить остановку', (tester) async {
      var added = 0;
      await tester.pumpWidget(
        buildBuilder(
          config: ServiceConfig.cars,
          intermediate: stops(2),
          onAdd: () => added++,
        ),
      );

      await tester.tap(find.text('+ Добавить остановку'));
      await tester.pumpAndSettle();
      expect(added, 1);
    });

    testWidgets('блокирует добавление при достижении лимита', (tester) async {
      await tester.pumpWidget(
        buildBuilder(
          config: ServiceConfig.cars,
          intermediate: stops(ServiceConfig.cars.maxIntermediateStops),
        ),
      );

      expect(find.text('Достигнут лимит остановок'), findsOneWidget);
      expect(find.text('+ Добавить остановку'), findsNothing);
    });

    testWidgets('удаление доступно только для промежуточных точек', (
      tester,
    ) async {
      final removed = <int>[];
      await tester.pumpWidget(
        buildBuilder(
          config: ServiceConfig.cars,
          intermediate: stops(2),
          onRemove: removed.add,
        ),
      );

      // По одной кнопке удаления на каждую промежуточную точку —
      // начальную и конечную удалить нельзя.
      final removeButtons = find.byIcon(Icons.close_rounded);
      expect(removeButtons, findsNWidgets(2));

      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();
      expect(removed, [0]);
    });

    testWidgets('позволяет изменить точку по нажатию', (tester) async {
      final edited = <int>[];
      await tester.pumpWidget(
        buildBuilder(
          config: ServiceConfig.cars,
          intermediate: stops(2),
          onEditStop: edited.add,
        ),
      );

      await tester.tap(find.text('Остановка 2').last);
      await tester.pumpAndSettle();
      expect(edited, isNotEmpty);
    });

    testWidgets('имеет ручки перетаскивания для смены порядка', (tester) async {
      await tester.pumpWidget(
        buildBuilder(config: ServiceConfig.cars, intermediate: stops(3)),
      );

      expect(find.byIcon(Icons.drag_handle_rounded), findsNWidgets(3));
      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(
        find.text('Удерживайте остановку, чтобы изменить её порядок'),
        findsOneWidget,
      );
    });
  });

  group('RouteBuilder — «Аманат»', () {
    testWidgets('использует тот же каркас, что и «Доставка»', (tester) async {
      await tester.pumpWidget(buildBuilder(config: ServiceConfig.amanat));

      expect(find.byType(AppRoutePointTile), findsNWidgets(2));
      expect(find.text('+ Добавить остановку'), findsNothing);
    });
  });

  group('RouteBuilder — незаполненный маршрут', () {
    testWidgets('конечная точка показывается подсказкой', (tester) async {
      await tester.pumpWidget(
        buildBuilder(config: ServiceConfig.delivery, destinationPoint: null),
      );

      expect(find.text(ServiceConfig.delivery.destinationHint), findsOneWidget);
    });
  });

  testAcrossScreenSizes('маршрут из 4 точек не переполняется', (
    tester,
    size,
  ) async {
    await tester.pumpWidget(
      buildBuilder(config: ServiceConfig.cars, intermediate: stops(3)),
    );
    await tester.pump();
    expect(find.text('Откуда'), findsOneWidget);
  });

  testWidgets('маршрут из 4 точек читается при масштабе текста 1.4', (
    tester,
  ) async {
    setScreenSize(tester, const Size(320, 568));

    await tester.pumpWidget(
      wrapWithApp(
        textScale: 1.4,
        Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: RouteBuilder(
              config: ServiceConfig.cars,
              fromTitle: start,
              fromSubtitle: null,
              fromIsSelected: true,
              destination: destination,
              intermediatePoints: stops(2),
              onEditFrom: () {},
              onEditDestination: () {},
              onEditIntermediate: (_) {},
              onAddIntermediate: () {},
              onRemoveIntermediate: (_) {},
              onReorderIntermediate: (_, __) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Откуда'), findsOneWidget);
  });
}
