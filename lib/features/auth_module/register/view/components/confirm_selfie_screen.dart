import 'package:dogo/features/auth_module/register/view/components/selfie_capture_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ConfirmSelfieScreen extends StatelessWidget {
  const ConfirmSelfieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _PageTitle(),
              const SizedBox(height: 6),
              const Text(
                'Сделайте селфи с паспортом',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  color: Color(0xFF9FA4AD),
                ),
              ),
              const SizedBox(height: 16),
              const _CaptureBox(),
              const SizedBox(height: 28),
              _PrimaryButton(
                text: 'Далее',
                onPressed: () => context.push(SelfieCaptureScreen.routePath),
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

class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Подтверждение',
      style: TextStyle(
        fontSize: 27,
        fontFamily: 'SFProDisplay',
        fontWeight: FontWeight.w600,
        height: 1.1,
        color: Colors.black,
      ),
    );
  }
}

class _CaptureBox extends StatelessWidget {
  const _CaptureBox();

  @override
  Widget build(BuildContext context) {
    final radius = 16.0;

    final h = MediaQuery.sizeOf(context).height;
    final boxHeight = (h * 0.58).clamp(460.0, 620.0);

    return Container(
      height: boxHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE6E9EF), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 28, offset: Offset(0, 12)),
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/img_id_card.png',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),

          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.text, required this.onPressed});
  final String text;
  final VoidCallback onPressed;

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
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          elevation: const WidgetStatePropertyAll(0),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.0),
          ),
        ),
        child: Text(text),
      ),
    );
  }
}
