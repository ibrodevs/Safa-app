import 'package:dogo/features/auth_module/register/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ConfirmWhatsappCodeScreen extends StatefulWidget {
  const ConfirmWhatsappCodeScreen({super.key});

  @override
  State<ConfirmWhatsappCodeScreen> createState() =>
      _ConfirmWhatsappCodeScreenState();
}

class _ConfirmWhatsappCodeScreenState
    extends State<ConfirmWhatsappCodeScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleWhatsappCode();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scheduleWhatsappCode() {
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final provider = context.read<AuthProvider>();
      final ok = await provider.sendWhatsappCode();
      if (!mounted) return;
      if (!ok) {
        final msg =
            provider.error ?? 'Не удалось отправить код в WhatsApp';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    });
  }

  Future<void> _onNext() async {
    final code = _ctrl.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите код из WhatsApp')),
      );
      return;
    }

    final provider = context.read<AuthProvider>();
    final ok = await provider.verifyCodeAndLogin(code: code);

    if (!mounted) return;

    if (ok) {
      context.go('/home');
    } else {
      final msg = provider.error ?? 'Неверный код из WhatsApp';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const side = 24.0;
    const titleColor = Color(0xFF000000);
    const subtitleColor = Color(0xFF8E8E93);
    const hintColor = Color(0xFFC9CCD3);
    const buttonColor = Color(0xFFE47F26);
    const cancelColor = Color(0xFFB8BAC2);

    final loading = context.watch<AuthProvider>().loading;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(side, 20, side, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Подтверждение',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 27,
                    height: 1.15,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Отслеживайте и узнавайте адреса\nактуальных складов  для доставки товаров',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.25,
                    color: subtitleColor,
                  ),
                ),
                const SizedBox(height: 26),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 28,
                        offset: Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _ctrl,
                    focusNode: _focus,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.25,
                      color: Colors.black,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Введите код с Whatsapp',
                      hintStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.25,
                        color: hintColor,
                      ),
                      isDense: true,
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: loading ? null : _onNext,
                    child: Text(
                      loading ? 'Проверка...' : 'Далее',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        height: 1.1,
                        letterSpacing: 0.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.go('/select_role'),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        'Отменить регистрацию',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          height: 1.2,
                          color: cancelColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
