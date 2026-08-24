import 'package:dogo/core/design/app_design.dart';
import 'package:dogo/core/widgets/app_widgets.dart';
import 'package:dogo/features/auth_module/login/widgets/auth_brand_header.dart';
import 'package:dogo/features/auth_module/register/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'components/register_dots_indicator.dart';

class ClientRegisterScreen extends StatefulWidget {
  const ClientRegisterScreen({super.key});

  @override
  State<ClientRegisterScreen> createState() => _ClientRegisterScreenState();
}

class _ClientRegisterScreenState extends State<ClientRegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  final _phoneFocus = FocusNode();
  final _passFocus = FocusNode();
  final _pass2Focus = FocusNode();

  String? _nameError;
  String? _phoneError;
  String? _passError;
  String? _pass2Error;
  String? _formError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pass.dispose();
    _pass2.dispose();
    _phoneFocus.dispose();
    _passFocus.dispose();
    _pass2Focus.dispose();
    super.dispose();
  }

  /// 12 цифр вида 996XXXXXXXXX — формат, который ждёт backend.
  String _digitsPhone() => KgPhoneInputFormatter.digitsOf(_phone.text);

  bool _validate() {
    final firstName = _name.text.trim();
    final phone = _digitsPhone();
    final pass = _pass.text;
    final pass2 = _pass2.text;

    final nameError = firstName.isEmpty ? 'Укажите имя' : null;
    final phoneError = (phone.length != 12 || !phone.startsWith('996'))
        ? 'Введите номер в формате +996 XXX XX-XX-XX'
        : null;
    final passError = pass.length < 6
        ? 'Пароль должен быть не короче 6 символов'
        : null;
    final pass2Error = pass2 != pass ? 'Пароли не совпадают' : null;

    setState(() {
      _nameError = nameError;
      _phoneError = phoneError;
      _passError = passError;
      _pass2Error = pass2Error;
      _formError = null;
    });

    return nameError == null &&
        phoneError == null &&
        passError == null &&
        pass2Error == null;
  }

  Future<void> _onNext() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    final provider = context.read<AuthProvider>();

    final ok = await provider.register(
      phoneNumber: _digitsPhone(),
      firstName: _name.text.trim(),
      lastName: '-',
      password: _pass.text,
      passwordConfirm: _pass2.text,
    );

    if (!mounted) return;

    if (ok) {
      context.push('/register/confirm/whatsapp');
      return;
    }

    setState(
      () => _formError = provider.error ?? 'Не удалось завершить регистрацию',
    );
  }

  void _clearFormError() {
    if (_formError != null) setState(() => _formError = null);
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;

    return AppScreenScaffold(
      backgroundColor: AppColors.surface,
      showBackButton: true,
      hideFooterWhenKeyboardVisible: true,
      footer: Column(
        children: [
          AppFormError(message: _formError),
          if (_formError != null) AppSpacing.gapSm,
          AppPrimaryButton(
            label: 'Далее',
            loadingLabel: 'Отправляем…',
            loading: loading,
            onPressed: _onNext,
          ),
          AppSpacing.gapSm,
          const Hero(
            tag: 'register_dots',
            child: RegisterDotsIndicator(activeIndex: 1),
          ),
          AppTextButton(
            label: 'Отменить регистрацию',
            muted: true,
            enabled: !loading,
            onPressed: () => context.pop(),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthBrandHeader(
            title: 'Регистрация',
            subtitle: 'Создайте аккаунт клиента, чтобы оформлять заказы',
          ),
          AppSpacing.gapXl,
          AppTextField(
            controller: _name,
            hint: 'Например, Иброхим',
            label: 'Имя',
            errorText: _nameError,
            enabled: !loading,
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.givenName],
            onChanged: (_) {
              _clearFormError();
              if (_nameError != null) setState(() => _nameError = null);
            },
            onSubmitted: (_) => _phoneFocus.requestFocus(),
          ),
          AppSpacing.gapMd,
          AppPhoneField(
            controller: _phone,
            focusNode: _phoneFocus,
            label: 'Телефон с WhatsApp',
            helperText: 'На этот номер придёт код подтверждения',
            errorText: _phoneError,
            enabled: !loading,
            onChanged: (_) {
              _clearFormError();
              if (_phoneError != null) setState(() => _phoneError = null);
            },
            onSubmitted: (_) => _passFocus.requestFocus(),
          ),
          AppSpacing.gapMd,
          AppPasswordField(
            controller: _pass,
            focusNode: _passFocus,
            label: 'Пароль',
            errorText: _passError,
            enabled: !loading,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            onChanged: (_) {
              _clearFormError();
              if (_passError != null) setState(() => _passError = null);
            },
            onSubmitted: (_) => _pass2Focus.requestFocus(),
          ),
          AppSpacing.gapMd,
          AppPasswordField(
            controller: _pass2,
            focusNode: _pass2Focus,
            hint: 'Повторите пароль',
            label: 'Подтверждение пароля',
            errorText: _pass2Error,
            enabled: !loading,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              _clearFormError();
              if (_pass2Error != null) setState(() => _pass2Error = null);
            },
            onSubmitted: (_) => _onNext(),
          ),
        ],
      ),
    );
  }
}
