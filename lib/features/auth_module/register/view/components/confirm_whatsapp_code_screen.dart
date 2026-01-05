import 'package:dogo/core/utils/app_colors.dart';
import 'package:dogo/core/widgets/app_text_field.dart';
import 'package:dogo/core/widgets/primary_button.dart';
import 'package:dogo/features/auth_module/register/provider/auth_provider.dart';
import 'package:dogo/features/auth_module/register/view/components/register_dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/utils/styles.dart';
import '../../../../../core/widgets/shadow_field.dart';

class ConfirmWhatsappCodeScreen extends StatefulWidget {
  const ConfirmWhatsappCodeScreen({super.key});

  @override
  State<ConfirmWhatsappCodeScreen> createState() =>
      _ConfirmWhatsappCodeScreenState();
}

class _ConfirmWhatsappCodeScreenState extends State<ConfirmWhatsappCodeScreen> {
  final _code = TextEditingController();
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
    _code.dispose();
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
        final msg = provider.error ?? 'Не удалось отправить код в WhatsApp';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    });
  }

  Future<void> _onNext() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите код из WhatsApp')));
      return;
    }

    final provider = context.read<AuthProvider>();
    final ok = await provider.verifyCodeAndLogin(code: code);

    if (!mounted) return;

    if (ok) {
      context.go('/home');
    } else {
      final msg = provider.error ?? 'Неверный код из WhatsApp';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final loading = context.watch<AuthProvider>().loading;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Подтверждение',
                      style: AppTextStyles.titleBlackStyle,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Отслеживайте и узнавайте адреса\nактуальных складов  для доставки товаров',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.25,
                        color: AppColors.subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 26),
                    ShadowField(
                      child: AppTextField(
                        controller: _code,
                        keyboardType: TextInputType.number,
                        hint: 'Введите код с Whatsapp',
                        prefixText: '  ',
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: PrimaryButton(
                        text: loading ? 'Проверка...' : 'Далее',
                        onPressed: loading ? null : _onNext,
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
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                              height: 1.2,
                              fontFamily: 'SFProDisplay',
                              color: AppColors.grey3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 405),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomPadding ,
              child: const Center(
                child: Hero(
                  tag: 'register_dots',
                  child: RegisterDotsIndicator(activeIndex: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
