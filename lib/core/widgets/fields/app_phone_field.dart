import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_text_field.dart';

/// Форматирует ввод кыргызского номера как `+996 XXX XX-XX-XX`.
///
/// В контроллере остаётся отформатированный текст, поэтому все места,
/// которые дальше делают `replaceAll(RegExp(r'\D'), '')`, получают ровно
/// те же 12 цифр, что и раньше. Формат отправки на backend не меняется.
class KgPhoneInputFormatter extends TextInputFormatter {
  const KgPhoneInputFormatter();

  static const String prefix = '+996 ';

  /// Извлекает 12 цифр (996XXXXXXXXX) из любого пользовательского ввода.
  static String digitsOf(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('996')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length > 9) digits = digits.substring(0, 9);
    return digits.isEmpty ? '' : '996$digits';
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('996')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length > 9) digits = digits.substring(0, 9);

    final buffer = StringBuffer(prefix);
    for (var i = 0; i < digits.length; i++) {
      if (i == 3 || i == 5 || i == 7) buffer.write(i == 3 ? ' ' : '-');
      buffer.write(digits[i]);
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Поле ввода номера телефона с кыргызской маской и телефонной клавиатурой.
class AppPhoneField extends StatelessWidget {
  const AppPhoneField({
    super.key,
    required this.controller,
    this.label,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.hint = '+996 700 00-00-00',
  });

  final TextEditingController controller;
  final String? label;
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hint: hint,
      label: label,
      errorText: errorText,
      helperText: helperText,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      prefixIcon: Icons.phone_outlined,
      autofillHints: const [AutofillHints.telephoneNumber],
      inputFormatters: const [KgPhoneInputFormatter()],
    );
  }
}
