import 'package:dogo/core/design/app_design.dart';
import 'package:dogo/core/widgets/app_widgets.dart';
import 'package:dogo/features/auth_module/login/widgets/auth_brand_header.dart';
import 'package:dogo/features/auth_module/register/data/models/register_request_model.dart';
import 'package:dogo/features/auth_module/register/provider/auth_provider.dart';
import 'package:dogo/features/auth_module/register/view/components/register_dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfirmWhatsappCodeScreen extends StatefulWidget {
  const ConfirmWhatsappCodeScreen({super.key});

  @override
  State<ConfirmWhatsappCodeScreen> createState() =>
      _ConfirmWhatsappCodeScreenState();
}

class _ConfirmWhatsappCodeScreenState extends State<ConfirmWhatsappCodeScreen> {
  final _code = TextEditingController();

  String? _codeError;
  String? _formError;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _formError = null;
    });

    final provider = context.read<AuthProvider>();
    final ok = await provider.sendWhatsappCode();
    if (!mounted) return;

    setState(() {
      _sending = false;
      if (!ok) {
        _formError = provider.error ?? 'Не удалось отправить код в WhatsApp';
      }
    });
  }

  Future<void> _onNext() async {
    FocusScope.of(context).unfocus();

    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _codeError = 'Введите код из WhatsApp');
      return;
    }
    if (code.length < 4) {
      setState(() => _codeError = 'Код слишком короткий');
      return;
    }

    setState(() {
      _codeError = null;
      _formError = null;
    });

    final provider = context.read<AuthProvider>();
    final ok = await provider.verifyCodeAndLogin(code: code);

    if (!mounted) return;

    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      final privacyAccepted = prefs.getBool('privacy_accepted') ?? false;
      final role = provider.role == UserRole.carrier
          ? 'carrier'
          : prefs.getString('user_role');

      if (!mounted) return;

      if (!privacyAccepted) {
        context.go('/privacy-policy');
      } else {
        context.go(role == 'carrier' ? '/home-carrier' : '/home');
      }
      return;
    }

    setState(() => _codeError = provider.error ?? 'Неверный код из WhatsApp');
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;

    return AppScreenScaffold(
      backgroundColor: AppColors.surface,
      showBackButton: true,
      footer: Column(
        children: [
          AppFormError(message: _formError),
          if (_formError != null) AppSpacing.gapSm,
          AppPrimaryButton(
            label: 'Подтвердить',
            loadingLabel: 'Проверяем…',
            loading: loading,
            onPressed: _onNext,
          ),
          AppSpacing.gapSm,
          const Hero(
            tag: 'register_dots',
            child: RegisterDotsIndicator(activeIndex: 2),
          ),
          AppTextButton(
            label: 'Отменить регистрацию',
            muted: true,
            enabled: !loading,
            onPressed: () => context.go('/select_role'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthBrandHeader(
            title: 'Подтверждение',
            subtitle:
                'Мы отправили код в WhatsApp на указанный номер. '
                'Введите его, чтобы завершить регистрацию.',
          ),
          AppSpacing.gapXl,
          AppTextField(
            controller: _code,
            hint: 'Код из WhatsApp',
            label: 'Код подтверждения',
            errorText: _codeError,
            enabled: !loading,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.sms_outlined,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofillHints: const [AutofillHints.oneTimeCode],
            onChanged: (_) {
              if (_codeError != null) setState(() => _codeError = null);
            },
            onSubmitted: (_) => _onNext(),
          ),
          AppSpacing.gapXs,
          Align(
            alignment: Alignment.centerLeft,
            child: AppTextButton(
              label: _sending ? 'Отправляем код…' : 'Отправить код повторно',
              enabled: !_sending && !loading,
              onPressed: _sendCode,
            ),
          ),
        ],
      ),
    );
  }
}
