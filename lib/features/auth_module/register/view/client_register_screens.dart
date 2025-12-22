import 'package:dogo/core/utils/app_colors.dart';
import 'package:dogo/core/widgets/primary_button.dart';
import 'package:dogo/core/widgets/shadow_field.dart';
import 'package:dogo/features/auth_module/register/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/eye_password.dart';
import 'components/register_dots_indicator.dart';
import 'widgets/client_title_block_widget.dart';

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

  bool _passObscured = true;
  bool _pass2Obscured = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pass.dispose();
    _pass2.dispose();
    super.dispose();
  }

  String _digitsPhone() {
    return _phone.text.replaceAll(RegExp(r'\D'), '');
  }

  Future<void> _onNext() async {
    final firstName = _name.text.trim();
    final phone = _digitsPhone();
    final pass = _pass.text;
    final pass2 = _pass2.text;

    if (firstName.isEmpty || phone.isEmpty || pass.isEmpty || pass2.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Заполните все поля')));
      return;
    }

    if (pass != pass2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Пароли не совпадают')));
      return;
    }

    final provider = context.read<AuthProvider>();

    final ok = await provider.register(
      phoneNumber: phone,
      firstName: firstName,
      lastName: '-',
      password: pass,
      passwordConfirm: pass2,
    );

    if (!mounted) return;

    if (ok) {
      context.push('/register/confirm/whatsapp');
    } else {
      final message = provider.error ?? 'Не удалось завершить регистрацию';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final loading = context.watch<AuthProvider>().loading;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ClientTitleBlock(),
              const SizedBox(height: 18),
              ShadowField(
                child: AppTextField(
                  controller: _name,
                  hint: 'Имя',
                  prefixText: '  ',
                ),
              ),
              const SizedBox(height: 14),
              ShadowField(
                child: AppTextField(
                  controller: _phone,
                  hint: 'Телефон с WhatsApp',
                  keyboardType: TextInputType.phone,
                  prefixText: '+',
                ),
              ),
              const SizedBox(height: 14),
              ShadowField(
                child: AppTextField(
                  controller: _pass,
                  hint: 'Пароль',
                  prefixText: '  ',
                  obscure: _passObscured,
                  suffix: PasswordEye(
                    obscured: _passObscured,
                    onTap: () {
                      setState(() {
                        _passObscured = !_passObscured;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              ShadowField(
                child: AppTextField(
                  controller: _pass2,
                  hint: 'Повторите пароль',
                  prefixText: '  ',
                  obscure: _pass2Obscured,
                  suffix: PasswordEye(
                    obscured: _pass2Obscured,
                    onTap: () {
                      setState(() {
                        _pass2Obscured = !_pass2Obscured;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: loading ? 'Отправка...' : 'Далее',
                onPressed: loading ? null : _onNext,
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Отменить регистрацию',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                      color: Color(0xFFB9C0C8),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: const Hero(
                  tag: 'register_dots',
                  child: RegisterDotsIndicator(activeIndex: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
