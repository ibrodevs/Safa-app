import 'package:dogo/features/auth_module/register/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(14, 28, 14, 24 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TitleBlock(),
              const SizedBox(height: 18),
              _ShadowField(
                child: _AppTextField(controller: _name, hint: 'Имя'),
              ),
              const SizedBox(height: 14),
              _ShadowField(
                child: _AppTextField(
                  controller: _phone,
                  hint: 'Телефон с WhatsApp',
                  keyboardType: TextInputType.phone,
                  prefixText: '+',
                ),
              ),
              const SizedBox(height: 14),
              _ShadowField(
                child: _AppTextField(
                  controller: _pass,
                  hint: 'Пароль',
                  obscure: _passObscured,
                  suffix: _PasswordEye(
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
              _ShadowField(
                child: _AppTextField(
                  controller: _pass2,
                  hint: 'Повторите пароль',
                  obscure: _pass2Obscured,
                  suffix: _PasswordEye(
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
              _PrimaryButton(
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
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Регистрация',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            height: 1.1,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Данные клиента',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            height: 1.15,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Отслеживайте и узнавайте адреса\nактуальных складов  для доставки товаров',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.25,
            color: Color(0xFF9FA4AD),
          ),
        ),
      ],
    );
  }
}

class _ShadowField extends StatelessWidget {
  const _ShadowField({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    super.key,
    this.controller,
    required this.hint,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.prefixText,
  });

  final TextEditingController? controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final String? prefixText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      cursorColor: Colors.black,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.25,
          color: Color(0xFFD0D5DD),
        ),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: suffix,
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: Colors.black,
        ),
      ),
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: Colors.black,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Color(0xFFE67E22)),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          elevation: const WidgetStatePropertyAll(0),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.0),
          ),
        ),
        child: Text(text),
      ),
    );
  }
}

class _PasswordEye extends StatelessWidget {
  const _PasswordEye({
    required this.obscured,
    required this.onTap,
  });

  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E9EF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          obscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          size: 20,
          color: const Color(0xFF8F97A3),
        ),
      ),
    );
  }
}
