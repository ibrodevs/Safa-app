import 'dart:io';

import 'package:dogo/features/auth_module/register/provider/auth_provider.dart';
import 'package:flutter/material.dart';

import 'package:dogo/core/design/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelfieCaptureScreen extends StatefulWidget {
  const SelfieCaptureScreen({super.key});

  static const routePath = '/selfie-capture';

  @override
  State<SelfieCaptureScreen> createState() => _SelfieCaptureScreenState();
}

class _SelfieCaptureScreenState extends State<SelfieCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selfie;

  Future<void> _takeSelfie(BuildContext context) async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85,
    );
    if (!mounted) return;
    if (file != null) {
      setState(() {
        _selfie = file;
      });
    }
  }

  Future<void> _submit(BuildContext context) async {
    final selfie = _selfie;
    if (selfie == null) {
      await _takeSelfie(context);
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.uploadSelfie(selfie.path);

    if (!context.mounted) return;

    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('carrier_pending', true);
      await prefs.setBool('is_logged_in', false);

      if (!context.mounted) return;
      context.go('/selfie-waiting');
    } else {
      final msg = auth.error ?? 'Не удалось загрузить селфи';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final loading = context.watch<AuthProvider>().loading;
    final hasPhoto = _selfie != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: Colors.black,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Селфи с паспортом',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Расположите лицо и паспорт в рамке, чтобы мы подтвердили вашу личность.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                      color: Color(0xFF9FA4AD),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: loading ? null : () => _takeSelfie(context),
                  child: _SelfieFrame(selfie: _selfie),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 64,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : () {
                              if (!hasPhoto) {
                                _takeSelfie(context);
                              } else {
                                _submit(context);
                              }
                            },
                      style: ButtonStyle(
                        backgroundColor: const WidgetStatePropertyAll(
                          AppColors.primary,
                        ),
                        foregroundColor: const WidgetStatePropertyAll(
                          Colors.white,
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        elevation: const WidgetStatePropertyAll(0),
                        textStyle: const WidgetStatePropertyAll(
                          TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1,
                          ),
                        ),
                      ),
                      child: loading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Отправляем селфи'),
                              ],
                            )
                          : Text(
                              hasPhoto ? 'Отправить селфи' : 'Сделать селфи',
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Фото будет использовано только для проверки личности и не передаётся третьим лицам.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFFB9C0C8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelfieFrame extends StatelessWidget {
  const _SelfieFrame({this.selfie});

  final XFile? selfie;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final boxHeight = (h * 0.58).clamp(420.0, 620.0);
    final radius = 24.0;

    return Container(
      height: boxHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFE6E9EF), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Positioned.fill(
              child: selfie != null
                  ? Image.file(File(selfie!.path), fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF020617),
                            Color(0xFF020617),
                            Color(0xFF020617),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
            ),
            if (selfie == null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.55),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            const Align(alignment: Alignment(0, -0.60), child: _HeadTarget()),
            SizedBox(height: 20),
            const Align(alignment: Alignment(0, 0.5), child: _CardTarget()),
          ],
        ),
      ),
    );
  }
}

class _HeadTarget extends StatelessWidget {
  const _HeadTarget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 170,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFF3E0), width: 3),
        color: Colors.black.withValues(alpha: 0.18),
      ),
      child: Icon(
        Icons.person_rounded,
        size: 76,
        color: Colors.white.withValues(alpha: 0.95),
      ),
    );
  }
}

class _CardTarget extends StatelessWidget {
  const _CardTarget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFF3E0), width: 3),
        color: Colors.black.withValues(alpha: 0.26),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.18),
            ),
            child: const Icon(
              Icons.badge_rounded,
              size: 26,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 10,
                  margin: const EdgeInsets.only(right: 40),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 8,
                  margin: const EdgeInsets.only(right: 80),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}
