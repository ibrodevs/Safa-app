import 'package:dogo/core/design/app_design.dart';
import 'package:dogo/core/widgets/app_widgets.dart';
import 'package:dogo/features/auth_module/register/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'widgets/auth_brand_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();

  String? _phoneError;
  String? _passwordError;
  String? _formError;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  /// 12 цифр вида 996XXXXXXXXX — формат, который ждёт backend.
  String _digitsPhone() => KgPhoneInputFormatter.digitsOf(_phone.text);

  bool _validate() {
    final phone = _digitsPhone();
    final password = _password.text;

    final phoneError = (phone.length != 12 || !phone.startsWith('996'))
        ? 'Введите номер в формате +996 XXX XX-XX-XX'
        : null;
    final passwordError = password.length < 6
        ? 'Пароль должен быть не короче 6 символов'
        : null;

    setState(() {
      _phoneError = phoneError;
      _passwordError = passwordError;
      _formError = null;
    });

    return phoneError == null && passwordError == null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    final provider = context.read<AuthProvider>();
    final ok = await provider.login(
      phoneNumber: _digitsPhone(),
      password: _password.text,
    );
    if (!mounted) return;

    if (!ok) {
      setState(
        () =>
            _formError = provider.error ?? 'Неверный номер телефона или пароль',
      );
      return;
    }

    final role = provider.role;
    context.go(role?.name == 'carrier' ? '/home-carrier' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;

    return AppScreenScaffold(
      backgroundColor: AppColors.surface,
      showBackButton: true,
      hideFooterWhenKeyboardVisible: true,
      onBack: () =>
          context.canPop() ? context.pop() : context.go('/select_role'),
      footer: Column(
        children: [
          AppFormError(message: _formError),
          if (_formError != null) AppSpacing.gapSm,
          AppPrimaryButton(
            label: 'Войти',
            loadingLabel: 'Входим…',
            loading: loading,
            onPressed: _submit,
          ),
          AppSpacing.gapXxs,
          AppTextButton(
            label: 'Нет аккаунта? Зарегистрироваться',
            enabled: !loading,
            onPressed: () => context.go('/select_role'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthBrandHeader(
            title: 'Вход',
            subtitle: 'Введите номер телефона и пароль от аккаунта',
          ),
          AppSpacing.gapXl,
          AppPhoneField(
            controller: _phone,
            label: 'Номер телефона',
            errorText: _phoneError,
            enabled: !loading,
            onChanged: (_) {
              if (_phoneError != null || _formError != null) {
                setState(() {
                  _phoneError = null;
                  _formError = null;
                });
              }
            },
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          AppSpacing.gapMd,
          AppPasswordField(
            controller: _password,
            focusNode: _passwordFocus,
            label: 'Пароль',
            errorText: _passwordError,
            enabled: !loading,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onChanged: (_) {
              if (_passwordError != null || _formError != null) {
                setState(() {
                  _passwordError = null;
                  _formError = null;
                });
              }
            },
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
    );
  }
}
