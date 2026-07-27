import 'package:dogo/core/design/app_theme.dart';
import 'package:dogo/core/widgets/app_widgets.dart';
import 'package:dogo/data/network/api_service.dart';
import 'package:dogo/features/auth_module/login/login_screen.dart';
import 'package:dogo/features/auth_module/register/data/models/register_request_model.dart';
import 'package:dogo/features/auth_module/register/data/repo/auth_repo.dart';
import 'package:dogo/features/auth_module/register/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../support/test_harness.dart';

/// Провайдер-дублёр: сетевые вызовы не выполняются, поведение `login`
/// задаётся тестом. Реальная логика авторизации при этом не подменяется —
/// экран по-прежнему работает через `AuthProvider`.
class _FakeAuthProvider extends AuthProvider {
  _FakeAuthProvider() : super(AuthRepository(ApiService.instance));

  /// Что вернёт [login]. Задаётся тестом перед `pumpWidget`.
  bool result = true;
  String? failureMessage;

  UserRole? loginRole;
  String? lastPhone;
  String? lastPassword;
  int loginCalls = 0;

  bool _loading = false;
  String? _error;

  @override
  bool get loading => _loading;

  @override
  String? get error => _error;

  @override
  UserRole? get role => loginRole;

  @override
  Future<bool> login({
    required String phoneNumber,
    required String password,
  }) async {
    loginCalls++;
    lastPhone = phoneNumber;
    lastPassword = password;

    _loading = true;
    notifyListeners();
    await Future<void>.delayed(Duration.zero);

    _loading = false;
    _error = result ? null : failureMessage;
    notifyListeners();

    return result;
  }
}

void main() {
  late _FakeAuthProvider auth;
  late List<String> visited;

  Widget buildApp({double textScale = 1.0}) {
    visited = [];

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(
          path: '/select_role',
          builder: (_, __) {
            visited.add('/select_role');
            return const Scaffold(body: Text('Выбор роли'));
          },
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) {
            visited.add('/home');
            return const Scaffold(body: Text('Главная клиента'));
          },
        ),
        GoRoute(
          path: '/home-carrier',
          builder: (_, __) {
            visited.add('/home-carrier');
            return const Scaffold(body: Text('Главная специалиста'));
          },
        ),
      ],
    );

    return ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: MaterialApp.router(
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String phone = '700123456',
    String password = 'secret123',
  }) async {
    await tester.enterText(find.byType(AppPhoneField), phone);
    await tester.enterText(
      find.descendant(
        of: find.byType(AppPasswordField),
        matching: find.byType(TextField),
      ),
      password,
    );
    await tester.pump();
  }

  setUp(() => auth = _FakeAuthProvider());

  group('Экран входа', () {
    testWidgets('показывает заголовок, поля и основную кнопку', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Вход'), findsOneWidget);
      expect(
        find.text('Введите номер телефона и пароль от аккаунта'),
        findsOneWidget,
      );
      expect(find.byType(AppPhoneField), findsOneWidget);
      expect(find.byType(AppPasswordField), findsOneWidget);
      expect(find.text('Войти'), findsOneWidget);
      expect(find.text('Нет аккаунта? Зарегистрироваться'), findsOneWidget);
    });

    testWidgets('форматирует номер по кыргызской маске', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.enterText(find.byType(AppPhoneField), '700123456');
      await tester.pump();

      expect(find.text('+996 700 12-34-56'), findsOneWidget);
    });

    testWidgets('использует телефонную клавиатуру для номера', (tester) async {
      await tester.pumpWidget(buildApp());

      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byType(AppPhoneField),
          matching: find.byType(TextField),
        ),
      );
      expect(field.keyboardType, TextInputType.phone);
    });

    testWidgets('пароль по умолчанию скрыт и раскрывается кнопкой', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());

      TextField passwordField() => tester.widget<TextField>(
        find.descendant(
          of: find.byType(AppPasswordField),
          matching: find.byType(TextField),
        ),
      );

      expect(passwordField().obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      expect(passwordField().obscureText, isFalse);
    });

    testWidgets('ошибку короткого номера показывает под полем номера', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());

      await fillForm(tester, phone: '700');
      await tester.tap(find.text('Войти'));
      await tester.pump();

      expect(
        find.text('Введите номер в формате +996 XXX XX-XX-XX'),
        findsOneWidget,
      );
      expect(auth.loginCalls, 0);
    });

    testWidgets('ошибку короткого пароля показывает под полем пароля', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());

      await fillForm(tester, password: '123');
      await tester.tap(find.text('Войти'));
      await tester.pump();

      expect(
        find.text('Пароль должен быть не короче 6 символов'),
        findsOneWidget,
      );
      expect(auth.loginCalls, 0);
    });

    testWidgets('неверные данные показывает общим блоком над кнопкой', (
      tester,
    ) async {
      auth
        ..result = false
        ..failureMessage = 'Неверный номер телефона или пароль';

      await tester.pumpWidget(buildApp());
      await fillForm(tester);

      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();

      expect(find.byType(AppFormError), findsWidgets);
      expect(find.text('Неверный номер телефона или пароль'), findsOneWidget);
      expect(visited, isEmpty);
    });

    testWidgets('передаёт на backend 12 цифр номера', (tester) async {
      await tester.pumpWidget(buildApp());
      await fillForm(tester);

      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();

      expect(auth.lastPhone, '996700123456');
      expect(auth.lastPassword, 'secret123');
    });

    testWidgets('после успешного входа ведёт клиента на /home', (tester) async {
      auth.loginRole = UserRole.client;

      await tester.pumpWidget(buildApp());
      await fillForm(tester);

      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();

      expect(visited, contains('/home'));
    });

    testWidgets('после успешного входа ведёт специалиста на /home-carrier', (
      tester,
    ) async {
      auth.loginRole = UserRole.carrier;

      await tester.pumpWidget(buildApp());
      await fillForm(tester);

      await tester.tap(find.text('Войти'));
      await tester.pumpAndSettle();

      expect(visited, contains('/home-carrier'));
    });

    testWidgets('ссылка ведёт на регистрацию', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.text('Нет аккаунта? Зарегистрироваться'));
      await tester.pumpAndSettle();

      expect(visited, contains('/select_role'));
    });

    testAcrossScreenSizes('не переполняется на всех ширинах', (
      tester,
      size,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      expect(find.text('Войти'), findsOneWidget);
    });

    testWidgets('кнопка остаётся доступной при открытой клавиатуре', (
      tester,
    ) async {
      setScreenSize(tester, const Size(320, 568));
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Имитируем клавиатуру: нижняя вставка забирает почти половину экрана.
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.reset);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Войти'), findsOneWidget);
    });

    for (final scale in kTextScales) {
      testWidgets('читается при системном масштабе текста $scale', (
        tester,
      ) async {
        setScreenSize(tester, const Size(360, 640));
        await tester.pumpWidget(buildApp(textScale: scale));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Вход'), findsOneWidget);
        expect(find.text('Войти'), findsOneWidget);
      });
    }
  });
}
