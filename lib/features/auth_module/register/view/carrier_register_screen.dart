import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../provider/auth_provider.dart';

class CarrierRegisterScreen extends StatefulWidget {
  const CarrierRegisterScreen({super.key});

  @override
  State<CarrierRegisterScreen> createState() => _CarrierRegisterScreenState();
}

class _CarrierRegisterScreenState extends State<CarrierRegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  bool _passObscured = true;
  bool _pass2Obscured = true;

  final ImagePicker _picker = ImagePicker();

  String? _idFrontPath;
  String? _idBackPath;

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

  void _onFrontTap() {
    _selectIdImage(isFront: true);
  }

  void _onBackTap() {
    _selectIdImage(isFront: false);
  }

  Future<void> _selectIdImage({required bool isFront}) async {
    final type = await showModalBottomSheet<_ImageSourceType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ImageSourceSheet(),
    );
    if (type == null) return;

    final source = type == _ImageSourceType.camera
        ? ImageSource.camera
        : ImageSource.gallery;

    final file = await _picker.pickImage(
      source: source,
      maxWidth: 2000,
      imageQuality: 90,
    );
    if (file == null) return;
    if (!mounted) return;

    setState(() {
      if (isFront) {
        _idFrontPath = file.path;
      } else {
        _idBackPath = file.path;
      }
    });
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

    if (_idFrontPath == null || _idBackPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Загрузите обе стороны документа')),
      );
      return;
    }

    final provider = context.read<AuthProvider>();
    final ok = await provider.register(
      phoneNumber: phone,
      firstName: firstName,
      lastName: '-',
      password: pass,
      passwordConfirm: pass2,
      idFront: _idFrontPath,
      idBack: _idBackPath,
    );

    if (!mounted) return;

    if (ok) {
      context.push('/register/confirm');
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
          padding: EdgeInsets.fromLTRB(24, 28, 24, 24 + bottom),
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
                  maxLenth: 10,
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
              const SizedBox(height: 18),
              _IdCardBlock(
                onFront: _onFrontTap,
                onBack: _onBackTap,
                frontPath: _idFrontPath,
                backPath: _idBackPath,
              ),
              const SizedBox(height: 28),
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
                      fontSize: 15,
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
    this.controller,
    required this.hint,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.prefixText,
    this.maxLenth,
  });

  final TextEditingController? controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final String? prefixText;
  final int? maxLenth;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      /*maxLength: maxLenth,*/
      maxLengthEnforcement: MaxLengthEnforcement.none,
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

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.title,
    required this.onTap,
    this.imagePath,
    required this.placeholderAsset,
  });

  final String title;
  final VoidCallback onTap;
  final String? imagePath;

  final String placeholderAsset;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 152,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6E9EF), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          padding: hasImage
              ? const EdgeInsets.all(8)
              : const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(imagePath!), fit: BoxFit.cover),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0x6B9E9E9E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E9EF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SvgPicture.asset(
                        placeholderAsset,
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _IdCardBlock extends StatelessWidget {
  const _IdCardBlock({
    required this.onFront,
    required this.onBack,
    this.frontPath,
    this.backPath,
  });

  final VoidCallback onFront;
  final VoidCallback onBack;
  final String? frontPath;
  final String? backPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ID Card',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Нажмите и загрузите документ с двух сторон',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: Color(0xFF9FA4AD),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _UploadTile(
                  title: 'Лицевая сторона',
                  onTap: onFront,
                  imagePath: frontPath,
                  placeholderAsset: 'assets/icons/ic_front_id_card.svg',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _UploadTile(
                  title: 'Обратная сторона',
                  onTap: onBack,
                  imagePath: backPath,
                  placeholderAsset: 'assets/icons/ic_back_id_card.svg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _ImageSourceType { camera, gallery }

class _ImageSourceSheet extends StatelessWidget {
  const _ImageSourceSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 30,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 52,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E9EF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Загрузить документ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Выберите источник фотографии',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.25,
                color: Color(0xFF9FA4AD),
              ),
            ),
            const SizedBox(height: 18),
            _ImageSourceTile(
              icon: Icons.photo_camera_rounded,
              title: 'Сделать фото',
              subtitle: 'Использовать камеру',
              onTap: () => Navigator.of(context).pop(_ImageSourceType.camera),
            ),
            const SizedBox(height: 10),
            _ImageSourceTile(
              icon: Icons.photo_library_rounded,
              title: 'Выбрать из галереи',
              subtitle: 'Использовать сохранённое фото',
              onTap: () => Navigator.of(context).pop(_ImageSourceType.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageSourceTile extends StatelessWidget {
  const _ImageSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6E9EF), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E9EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: const Color(0xFF8F97A3)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                        color: Color(0xFF9FA4AD),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordEye extends StatelessWidget {
  const _PasswordEye({required this.obscured, required this.onTap});

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
