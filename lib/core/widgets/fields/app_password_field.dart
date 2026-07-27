import 'package:flutter/material.dart';

import '../../design/app_design.dart';
import 'app_text_field.dart';

/// Поле пароля со встроенной кнопкой показа/скрытия.
///
/// Кнопка «глаз» имеет область нажатия 44×44 px (раньше было ~30 px).
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    this.controller,
    this.hint = 'Пароль',
    this.label,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final String hint;
  final String? label;
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      hint: widget.hint,
      label: widget.label,
      errorText: widget.errorText,
      helperText: widget.helperText,
      enabled: widget.enabled,
      obscure: _obscured,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      focusNode: widget.focusNode,
      prefixIcon: Icons.lock_outline_rounded,
      autofillHints: widget.autofillHints,
      suffix: Semantics(
        button: true,
        label: _obscured ? 'Показать пароль' : 'Скрыть пароль',
        child: InkWell(
          onTap: () => setState(() => _obscured = !_obscured),
          borderRadius: AppRadius.allSm,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Icon(
                _obscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
