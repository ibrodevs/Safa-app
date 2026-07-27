import 'package:dogo/core/utils/order_status_view.dart';
import 'package:dogo/core/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_harness.dart';

void main() {
  Widget buildCard({
    String status = 'pending',
    int? stopsCount = 3,
    String? price = '450 сом',
    String title = 'Доставка до Дордоя',
    VoidCallback? onTap,
  }) {
    return wrapWithApp(
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: AppOrderCard(
            number: 'Заказ №A-1024',
            title: title,
            status: OrderStatusView.of(status),
            date: '14 апреля, 23:57',
            serviceLabel: 'Мест: 2',
            stopsCount: stopsCount,
            priceLabel: price,
            fromTitle: 'Дордой, контейнер 125',
            toTitle: 'Ошский базар, контейнер 12',
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );
  }

  group('AppOrderCard', () {
    testWidgets('показывает номер, название, дату и стоимость', (tester) async {
      await tester.pumpWidget(buildCard());

      expect(find.text('Заказ №A-1024'), findsOneWidget);
      expect(find.text('Доставка до Дордоя'), findsOneWidget);
      expect(find.text('14 апреля, 23:57'), findsOneWidget);
      expect(find.text('450 сом'), findsOneWidget);
      expect(find.text('Остановок: 3'), findsOneWidget);
    });

    testWidgets('показывает маршрут: откуда и куда', (tester) async {
      await tester.pumpWidget(buildCard());

      expect(find.text('Дордой, контейнер 125'), findsOneWidget);
      expect(find.text('Ошский базар, контейнер 12'), findsOneWidget);
    });

    testWidgets('статус выводится текстом, а не только цветом', (tester) async {
      await tester.pumpWidget(buildCard(status: 'canceled'));

      expect(find.text('Отменён'), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });

    testWidgets('разные статусы дают разные подписи', (tester) async {
      final expected = <String, String>{
        'pending': 'Поиск исполнителя',
        'assigned': 'Назначен',
        'in_transit': 'В пути',
        'completed': 'Выполнен',
        'canceled': 'Отменён',
      };

      for (final entry in expected.entries) {
        await tester.pumpWidget(buildCard(status: entry.key));
        await tester.pump();
        expect(
          find.text(entry.value),
          findsOneWidget,
          reason:
              'Статус ${entry.key} должен показываться как '
              '«${entry.value}»',
        );
      }
    });

    testWidgets('скрывает пустые метаданные', (tester) async {
      await tester.pumpWidget(buildCard(stopsCount: 0, price: null));

      expect(find.textContaining('Остановок'), findsNothing);
      expect(find.textContaining('сом'), findsNothing);
    });

    testWidgets('открывает детали по нажатию', (tester) async {
      var taps = 0;
      await tester.pumpWidget(buildCard(onTap: () => taps++));

      await tester.tap(find.text('Доставка до Дордоя'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testAcrossScreenSizes('не переполняется на всех ширинах', (
      tester,
      size,
    ) async {
      await tester.pumpWidget(
        buildCard(
          title:
              'Очень длинное название заказа, которое обязано '
              'переноситься и обрезаться, а не ломать вёрстку',
        ),
      );
      await tester.pump();
      expect(find.text('Заказ №A-1024'), findsOneWidget);
    });

    testWidgets('выдерживает системный масштаб текста 1.4', (tester) async {
      setScreenSize(tester, const Size(320, 568));

      await tester.pumpWidget(
        wrapWithApp(
          textScale: 1.4,
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AppOrderCard(
                number: 'Заказ №A-1024',
                title: 'Доставка до Дордоя',
                status: OrderStatusView.of('in_transit'),
                date: '14 апреля, 23:57',
                stopsCount: 3,
                priceLabel: '450 сом',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('В пути'), findsOneWidget);
    });
  });

  group('OrderFilter', () {
    test('активные, завершённые и отменённые не пересекаются', () {
      expect(OrderFilter.active.matches('pending'), isTrue);
      expect(OrderFilter.active.matches('in_transit'), isTrue);
      expect(OrderFilter.active.matches('completed'), isFalse);

      expect(OrderFilter.completed.matches('completed'), isTrue);
      expect(OrderFilter.completed.matches('delivered'), isTrue);
      expect(OrderFilter.completed.matches('canceled'), isFalse);

      expect(OrderFilter.canceled.matches('canceled'), isTrue);
      expect(OrderFilter.canceled.matches('cancelled'), isTrue);
      expect(OrderFilter.canceled.matches('pending'), isFalse);
    });

    test('фильтр «все» пропускает любой статус', () {
      for (final status in ['pending', 'completed', 'canceled', 'что-то']) {
        expect(OrderFilter.all.matches(status), isTrue);
      }
    });
  });
}
