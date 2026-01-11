import 'package:dogo/core/widgets/app_text_field.dart';
import 'package:dogo/core/widgets/eye_password.dart';
import 'package:dogo/core/widgets/primary_button.dart';
import 'package:dogo/core/widgets/shadow_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';
import 'components/image_source_sheet.dart';
import 'widgets/carrier_title_block_widget.dart';
import 'widgets/id_card_block.dart';
import 'widgets/image_source_tile_widget.dart';

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
    final type = await showModalBottomSheet<ImageSourceType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const ImageSourceSheet(),
    );
    if (type == null) return;

    final source = type == ImageSourceType.camera
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
              const CarrierTitleBlock(),
              const SizedBox(height: 18),
              ShadowField(
                child: AppTextField(controller: _name, hint: 'Имя'),
              ),
              const SizedBox(height: 14),
              ShadowField(
                child: AppTextField(
                  controller: _phone,
                  hint: 'Телефон с WhatsApp',
                  keyboardType: TextInputType.phone,
                  prefixText: '+',
                  maxLenth: 10,
                ),
              ),
              const SizedBox(height: 14),
              ShadowField(
                child: AppTextField(
                  controller: _pass,
                  hint: 'Пароль',
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
              const SizedBox(height: 18),
              IdCardBlock(
                onFront: _onFrontTap,
                onBack: _onBackTap,
                frontPath: _idFrontPath,
                backPath: _idBackPath,
              ),
              const SizedBox(height: 28),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                      color: Color(0xFFB9C0C8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}