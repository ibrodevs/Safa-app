import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dogo/core/utils/friendly_error.dart';
import 'package:dogo/core/widgets/app_widgets.dart';
import 'package:dogo/data/network/model/api_exeptions_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_harness.dart';

void main() {
  group('AppEmptyState', () {
    testWidgets('показывает иконку, текст и основное действие', (tester) async {
      var taps = 0;

      await tester.pumpWidget(
        wrapWithApp(
          Scaffold(
            body: AppEmptyState(
              title: 'Заказов пока нет',
              message: 'Оформите первый заказ',
              icon: Icons.local_shipping_outlined,
              actionLabel: 'Создать заказ',
              onAction: () => taps++,
            ),
          ),
        ),
      );

      expect(find.text('Заказов пока нет'), findsOneWidget);
      expect(find.text('Оформите первый заказ'), findsOneWidget);
      expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);

      await tester.tap(find.text('Создать заказ'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('работает без действия', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          const Scaffold(body: AppEmptyState(title: 'Ничего не найдено')),
        ),
      );

      expect(find.text('Ничего не найдено'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testAcrossScreenSizes('не переполняется на всех ширинах', (
      tester,
      size,
    ) async {
      await tester.pumpWidget(
        wrapWithApp(
          Scaffold(
            body: AppEmptyState(
              title: 'Заказов пока нет',
              message:
                  'Оформите первый заказ — он появится здесь '
                  'вместе со статусом и стоимостью',
              actionLabel: 'Создать заказ',
              onAction: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Заказов пока нет'), findsOneWidget);
    });
  });

  group('AppErrorState', () {
    testWidgets('предлагает повторить загрузку', (tester) async {
      var retries = 0;

      await tester.pumpWidget(
        wrapWithApp(
          Scaffold(
            body: AppErrorState(
              error: ApiException('Сервис недоступен', statusCode: 503),
              onRetry: () => retries++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();
      expect(retries, 1);
    });

    testWidgets('офлайн показывается отдельным сообщением', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          Scaffold(
            body: AppErrorState(
              error: DioException(
                requestOptions: RequestOptions(path: '/'),
                type: DioExceptionType.connectionError,
              ),
              onRetry: () {},
            ),
          ),
        ),
      );

      expect(find.text('Нет соединения'), findsOneWidget);
      expect(find.text(kOfflineErrorMessage), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });

    testWidgets('не показывает технический текст ошибки', (tester) async {
      const html = '<html><body>500 Internal Server Error</body></html>';

      await tester.pumpWidget(
        wrapWithApp(Scaffold(body: AppErrorState(error: ApiException(html)))),
      );

      expect(find.textContaining('<html>'), findsNothing);
      expect(find.textContaining('500'), findsNothing);
    });
  });

  group('friendlyErrorMessage', () {
    test('переводит отсутствие сети в понятное сообщение', () {
      expect(
        friendlyErrorMessage(const SocketException('failed host lookup')),
        kOfflineErrorMessage,
      );
      expect(
        friendlyErrorMessage(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionError,
          ),
        ),
        kOfflineErrorMessage,
      );
    });

    test('скрывает HTML, JSON и обёртки исключений', () {
      for (final raw in [
        '<html>500</html>',
        '{"detail": "server error"}',
        'DioException [bad response]: 500',
        'ApiException(500, ошибка)',
        'Exception: что-то сломалось',
      ]) {
        expect(
          friendlyErrorMessage(raw, fallback: 'Общая ошибка'),
          'Общая ошибка',
          reason: 'Технический текст «$raw» не должен доходить до экрана',
        );
      }
    });

    test('пропускает короткое человекочитаемое сообщение', () {
      expect(
        friendlyErrorMessage(ApiException('Неверный код из WhatsApp')),
        'Неверный код из WhatsApp',
      );
    });

    test('5xx превращается в сообщение о недоступности сервера', () {
      expect(
        friendlyErrorMessage(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/'),
              statusCode: 500,
            ),
          ),
        ),
        'Сервер временно недоступен. Попробуйте позже.',
      );
    });

    test('401 предлагает войти заново', () {
      expect(
        friendlyErrorMessage(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: RequestOptions(path: '/'),
              statusCode: 401,
            ),
          ),
        ),
        'Сессия истекла. Войдите в аккаунт заново.',
      );
    });
  });

  group('AppLoadingState', () {
    testWidgets('показывает индикатор и пояснение', (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          const Scaffold(body: AppLoadingState(message: 'Загружаем заказ…')),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Загружаем заказ…'), findsOneWidget);
    });
  });
}
