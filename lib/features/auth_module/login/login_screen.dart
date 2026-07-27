import 'package:dogo/core/utils/snackbar_utils.dart';
import 'package:dogo/core/widgets/app_text_field.dart';
import 'package:dogo/core/widgets/eye_password.dart';
import 'package:dogo/core/widgets/primary_button.dart';
import 'package:dogo/core/widgets/shadow_field.dart';
import 'package:dogo/features/auth_module/register/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _obscured = true;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  String _digitsPhone() => _phone.text.replaceAll(RegExp(r'\D'), '');

  Future<void> _submit() async {
    final phone = _digitsPhone();
    final password = _password.text;

    if (phone.length != 12 || !phone.startsWith('996')) {
      AppSnackBar.showError(
        context,
        message: 'Введите номер в формате 996XXXXXXXXX',
      );
      return;
    }
    if (password.length < 6) {
      AppSnackBar.showError(context, message: 'Введите пароль');
      return;
    }

    final provider = context.read<AuthProvider>();
    final ok = await provider.login(phoneNumber: phone, password: password);
    if (!mounted) return;

    if (!ok) {
      AppSnackBar.showError(
        context,
        message: provider.error ?? 'Не удалось войти',
      );
      return;
    }

    final role = provider.role;
    context.go(role?.name == 'carrier' ? '/home-carrier' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 32, 24, 24 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              const SizedBox(height: 28),
              const Text(
                'Вход',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Введите номер телефона и пароль от аккаунта',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                  color: Color(0xFF8F97A3),
                ),
              ),
              const SizedBox(height: 28),
              ShadowField(
                child: AppTextField(
                  controller: _phone,
                  hint: 'Номер телефона',
                  keyboardType: TextInputType.phone,
                  prefixText: '+',
                  maxLenth: 12,
                ),
              ),
              const SizedBox(height: 14),
              ShadowField(
                child: AppTextField(
                  controller: _password,
                  hint: 'Пароль',
                  obscure: _obscured,
                  suffix: PasswordEye(
                    obscured: _obscured,
                    onTap: () => setState(() => _obscured = !_obscured),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              PrimaryButton(
                text: loading ? 'Входим...' : 'Войти',
                onPressed: loading ? null : _submit,
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: loading ? null : () => context.go('/select_role'),
                  child: const Text(
                    'Нет аккаунта? Зарегистрироваться',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE67E22),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
