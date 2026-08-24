import 'package:dogo/core/design/app_design.dart';
import 'package:dogo/core/widgets/app_widgets.dart';
import 'package:dogo/features/auth_module/login/widgets/auth_brand_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/models/register_request_model.dart';
import '../provider/auth_provider.dart';
import 'components/image_source_sheet.dart';
import 'components/register_dots_indicator.dart';
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

  final _phoneFocus = FocusNode();
  final _passFocus = FocusNode();
  final _pass2Focus = FocusNode();

  final ImagePicker _picker = ImagePicker();

  String? _idFrontPath;
  String? _idBackPath;

  String? _nameError;
  String? _phoneError;
  String? _passError;
  String? _pass2Error;
  String? _formError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pass.dispose();
    _pass2.dispose();
    _phoneFocus.dispose();
    _passFocus.dispose();
    _pass2Focus.dispose();
    super.dispose();
  }

  String _digitsPhone() => KgPhoneInputFormatter.digitsOf(_phone.text);

  Future<void> _selectIdImage({required bool isFront}) async {
    FocusScope.of(context).unfocus();

    final type = await showAppBottomSheet<ImageSourceType>(
      context: context,
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
    if (file == null || !mounted) return;

    setState(() {
      if (isFront) {
        _idFrontPath = file.path;
      } else {
        _idBackPath = file.path;
      }
      _formError = null;
    });
  }

  bool _validate() {
    final firstName = _name.text.trim();
    final phone = _digitsPhone();
    final pass = _pass.text;
    final pass2 = _pass2.text;

    final nameError = firstName.isEmpty ? 'Укажите имя' : null;
    final phoneError = (phone.length != 12 || !phone.startsWith('996'))
        ? 'Введите номер в формате +996 XXX XX-XX-XX'
        : null;
    final passError = pass.length < 6
        ? 'Пароль должен быть не короче 6 символов'
        : null;
    final pass2Error = pass2 != pass ? 'Пароли не совпадают' : null;

    final documentsError = (_idFrontPath == null || _idBackPath == null)
        ? 'Загрузите обе стороны документа'
        : null;

    setState(() {
      _nameError = nameError;
      _phoneError = phoneError;
      _passError = passError;
      _pass2Error = pass2Error;
      _formError = documentsError;
    });

    return nameError == null &&
        phoneError == null &&
        passError == null &&
        pass2Error == null &&
        documentsError == null;
  }

  Future<void> _onNext() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    final phone = _digitsPhone();
    final provider = context.read<AuthProvider>();

    final ok = await provider.register(
      phoneNumber: phone,
      firstName: _name.text.trim(),
      lastName: '-',
      password: _pass.text,
      passwordConfirm: _pass2.text,
      idFront: _idFrontPath,
      idBack: _idBackPath,
    );

    if (!mounted) return;

    if (ok) {
      context.push('/register/confirm');
      return;
    }

    setState(
      () => _formError = provider.error ?? 'Не удалось завершить регистрацию',
    );
  }

  void _clearFormError() {
    if (_formError != null) setState(() => _formError = null);
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    final specialistType =
        context.watch<AuthProvider>().specialistType ?? SpecialistType.delivery;

    return AppScreenScaffold(
      backgroundColor: AppColors.surface,
      showBackButton: true,
      hideFooterWhenKeyboardVisible: true,
      footer: Column(
        children: [
          AppFormError(message: _formError),
          if (_formError != null) AppSpacing.gapSm,
          AppPrimaryButton(
            label: 'Далее',
            loadingLabel: 'Отправляем…',
            loading: loading,
            onPressed: _onNext,
          ),
          AppSpacing.gapSm,
          const Hero(
            tag: 'register_dots',
            child: RegisterDotsIndicator(activeIndex: 1),
          ),
          AppTextButton(
            label: 'Отменить регистрацию',
            muted: true,
            enabled: !loading,
            onPressed: () => context.pop(),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthBrandHeader(
            title: 'Регистрация: ${specialistType.title}',
            subtitle:
                'Заполните данные и загрузите документ, '
                'чтобы принимать заказы',
          ),
          AppSpacing.gapXl,
          AppTextField(
            controller: _name,
            hint: 'Например, Иброхим',
            label: 'Имя',
            errorText: _nameError,
            enabled: !loading,
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {
              _clearFormError();
              if (_nameError != null) setState(() => _nameError = null);
            },
            onSubmitted: (_) => _phoneFocus.requestFocus(),
          ),
          AppSpacing.gapMd,
          AppPhoneField(
            controller: _phone,
            focusNode: _phoneFocus,
            label: 'Номер телефона',
            errorText: _phoneError,
            enabled: !loading,
            onChanged: (_) {
              _clearFormError();
              if (_phoneError != null) setState(() => _phoneError = null);
            },
            onSubmitted: (_) => _passFocus.requestFocus(),
          ),
          AppSpacing.gapMd,
          AppPasswordField(
            controller: _pass,
            focusNode: _passFocus,
            label: 'Пароль',
            errorText: _passError,
            enabled: !loading,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              _clearFormError();
              if (_passError != null) setState(() => _passError = null);
            },
            onSubmitted: (_) => _pass2Focus.requestFocus(),
          ),
          AppSpacing.gapMd,
          AppPasswordField(
            controller: _pass2,
            focusNode: _pass2Focus,
            hint: 'Повторите пароль',
            label: 'Подтверждение пароля',
            errorText: _pass2Error,
            enabled: !loading,
            textInputAction: TextInputAction.done,
            onChanged: (_) {
              _clearFormError();
              if (_pass2Error != null) setState(() => _pass2Error = null);
            },
            onSubmitted: (_) => _onNext(),
          ),
          AppSpacing.gapXl,
          const AppSectionHeader(
            title: 'Документ',
            subtitle: 'Нужны обе стороны удостоверения личности',
          ),
          AppSpacing.gapSm,
          IdCardBlock(
            onFront: () => _selectIdImage(isFront: true),
            onBack: () => _selectIdImage(isFront: false),
            frontPath: _idFrontPath,
            backPath: _idBackPath,
          ),
        ],
      ),
    );
  }
}
