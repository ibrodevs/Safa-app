import 'package:dogo/core/design/app_design.dart';
import 'package:dogo/core/utils/order_status_view.dart';
import 'package:dogo/core/widgets/app_widgets.dart';
import 'package:dogo/features/main_module/history/view/components/order_filter_tabs.dart';
import 'package:dogo/features/main_module/home/components/home_header.dart';
import 'package:dogo/features/main_module/map/data/model/delivery_point_model.dart';
import 'package:dogo/features/main_module/map/data/model/delivery_refs_models.dart';
import 'package:dogo/features/main_module/map/view/components/container_details_sheet.dart';
import 'package:dogo/features/main_module/map/view/components/service_order_panel.dart';
import 'package:dogo/features/main_module/services/service_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_harness.dart';

/// Матрица адаптивности: основные блоки интерфейса рендерятся на всех
/// заявленных размерах экрана без исключений и overflow (ТЗ §26).
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

  const destination = DeliveryPoint(
    title: 'Ошский базар',
    subtitle: 'Контейнер: 12 • Проход: 3',
    lat: 42.87,
    lon: 74.58,
  );

  group('Главное меню', () {
    testAcrossScreenSizes('шапка и три карточки сервисов', (tester, _) async {
      await tester.pumpWidget(
        wrapWithApp(
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  HomeHeader(
                    greeting: 'Добрый день, Иброхим',
                    prompt: 'Куда отправим сегодня?',
                    onNotifications: () {},
                    onProfile: () {},
                  ),
                  AppSpacing.gapLg,
                  for (final config in ServiceConfig.all) ...[
                    AppServiceCard(
                      title: config.title,
                      description: config.shortDescription,
                      icon: config.icon,
                      accent: config.accent,
                      accentSoft: config.accentSoft,
                      imageAsset: config.imageAsset,
                      onTap: () {},
                    ),
                    AppSpacing.gapSm,
                  ],
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Доставка'), findsOneWidget);
      expect(find.text('Тачки'), findsOneWidget);
      expect(find.text('Аманат'), findsOneWidget);
    });
  });

  group('Создание заказа', () {
    for (final config in ServiceConfig.all) {
      testAcrossScreenSizes('панель сервиса «${config.title}»', (
        tester,
        _,
      ) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          wrapWithApp(
            Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: ServiceOrderPanel(
                  config: config,
                  fromTitle: 'Дордой, вход 5',
                  fromSubtitle: 'Контейнер: 125',
                  fromIsSelected: true,
                  destination: destination,
                  intermediatePoints: config.allowsIntermediateStops
                      ? const [
                          DeliveryPoint(
                            title: 'Остановка 1',
                            subtitle: 'Контейнер: 200',
                            lat: 42.9,
                            lon: 74.6,
                          ),
                        ]
                      : const [],
                  descriptionController: controller,
                  creating: false,
                  onEditFrom: () {},
                  onEditDestination: () {},
                  onEditIntermediate: (_) {},
                  onAddIntermediate: () {},
                  onRemoveIntermediate: (_) {},
                  onReorderIntermediate: (_, __) {},
                  onSubmit: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text(config.title), findsOneWidget);
        expect(find.text(config.primaryActionLabel), findsOneWidget);
      });
    }

    testWidgets('«Аманат» показывает поле описания, «Доставка» — нет', (
      tester,
    ) async {
      setScreenSize(tester, const Size(390, 844));

      Future<void> pumpPanel(ServiceConfig config) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          wrapWithApp(
            Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: ServiceOrderPanel(
                  config: config,
                  fromTitle: 'Дордой',
                  fromSubtitle: null,
                  fromIsSelected: true,
                  destination: destination,
                  intermediatePoints: const [],
                  descriptionController: controller,
                  creating: false,
                  onEditFrom: () {},
                  onEditDestination: () {},
                  onEditIntermediate: (_) {},
                  onAddIntermediate: () {},
                  onRemoveIntermediate: (_) {},
                  onReorderIntermediate: (_, __) {},
                  onSubmit: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      await pumpPanel(ServiceConfig.amanat);
      expect(find.text('Что передаём'), findsOneWidget);

      await pumpPanel(ServiceConfig.delivery);
      expect(find.text('Что передаём'), findsNothing);
    });

    testWidgets('кнопка заблокирована, пока не выбрана конечная точка', (
      tester,
    ) async {
      setScreenSize(tester, const Size(390, 844));
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrapWithApp(
          Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ServiceOrderPanel(
                config: ServiceConfig.delivery,
                fromTitle: 'Дордой',
                fromSubtitle: null,
                fromIsSelected: true,
                destination: null,
                intermediatePoints: const [],
                descriptionController: controller,
                creating: false,
                onEditFrom: () {},
                onEditDestination: () {},
                onEditIntermediate: (_) {},
                onAddIntermediate: () {},
                onRemoveIntermediate: (_) {},
                onReorderIntermediate: (_, __) {},
                onSubmit: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(find.textContaining('чтобы продолжить'), findsOneWidget);
    });
  });

  group('Список заказов', () {
    testAcrossScreenSizes('фильтры и карточки', (tester, _) async {
      await tester.pumpWidget(
        wrapWithApp(
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  OrderFilterTabs(
                    selected: OrderFilter.all,
                    counts: const {
                      OrderFilter.all: 12,
                      OrderFilter.active: 3,
                      OrderFilter.completed: 8,
                      OrderFilter.canceled: 1,
                    },
                    onChanged: (_) {},
                  ),
                  AppSpacing.gapMd,
                  AppOrderCard(
                    number: 'Заказ №A-1024',
                    title: 'Доставка до Дордоя',
                    status: OrderStatusView.of('in_transit'),
                    date: '14 апреля, 23:57',
                    stopsCount: 3,
                    priceLabel: '450 сом',
                    fromTitle: 'Дордой, контейнер 125',
                    toTitle: 'Ошский базар, контейнер 12',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Активные'), findsOneWidget);
      expect(find.text('В пути'), findsOneWidget);
    });
  });

  group('Профиль', () {
    testAcrossScreenSizes('группы настроек', (tester, _) async {
      await tester.pumpWidget(
        wrapWithApp(
          Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  AppTileGroup(
                    title: 'Аккаунт',
                    children: [
                      AppListTile(
                        title: 'Личные данные',
                        subtitle: 'Имя, город, фотография',
                        icon: Icons.person_outline,
                        onTap: () {},
                      ),
                      AppListTile(
                        title: 'История пополнений и трат',
                        icon: Icons.history,
                        onTap: () {},
                      ),
                    ],
                  ),
                  AppSpacing.gapMd,
                  AppSecondaryButton(
                    label: 'Выйти из аккаунта',
                    icon: Icons.logout_rounded,
                    danger: true,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Личные данные'), findsOneWidget);
      expect(find.text('Выйти из аккаунта'), findsOneWidget);
    });
  });

  group('Bottom sheet выбора контейнера', () {
    testAcrossScreenSizes('карточка контейнера', (tester, _) async {
      await tester.pumpWidget(
        wrapWithApp(
          Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ContainerDetailsSheet(
                container: container,
                config: ServiceConfig.cars,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Контейнер 125'), findsWidgets);
      expect(find.text('Дордой'), findsOneWidget);
      expect(find.text('Подтвердить остановку'), findsOneWidget);
    });

    testWidgets('для «Доставки» остановку добавить нельзя', (tester) async {
      setScreenSize(tester, const Size(390, 844));

      await tester.pumpWidget(
        wrapWithApp(
          Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ContainerDetailsSheet(
                container: container,
                config: ServiceConfig.delivery,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Подтвердить остановку'), findsNothing);
      expect(find.text('Точка отправки'), findsOneWidget);
    });
  });

  group('Bottom sheet — общий каркас', () {
    testAcrossScreenSizes('не переполняется и учитывает клавиатуру', (
      tester,
      size,
    ) async {
      await tester.pumpWidget(
        wrapWithApp(
          Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: AppBottomSheet(
                title: 'Точка доставки',
                subtitle: 'Выберите базар доставки',
                footer: AppPrimaryButton(
                  label: 'Подтвердить точку',
                  onPressed: () {},
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < 8; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppTextField(
                          hint: 'Поле $i',
                          label: 'Подпись $i',
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Точка доставки'), findsOneWidget);
      expect(find.text('Подтвердить точку'), findsOneWidget);
    });

    testWidgets('поднимается над клавиатурой', (tester) async {
      setScreenSize(tester, const Size(360, 640));

      await tester.pumpWidget(
        wrapWithApp(
          const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: AppBottomSheet(
                title: 'Точка доставки',
                child: SizedBox(height: 200),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Точка доставки'), findsOneWidget);
    });
  });
}
