import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/app_design.dart';

/// Универсальное поле ввода.
///
/// Поддерживает обычное состояние, фокус, заполненное состояние, ошибку,
/// `disabled`, helper text, prefix и suffix иконки.
///
/// API — суперсет старого `core/widgets/app_text_field.dart`: параметры
/// `hint`, `obscure`, `suffix`, `prefixText`, `maxLenth` сохранены, поэтому
/// существующие вызовы продолжают работать.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    required this.hint,
    this.label,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.prefixText,
    // ignore: no_leading_underscores_for_local_identifiers
    this.maxLenth,
    this.maxLength,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.enabled = true,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
  });

  final TextEditingController? controller;
  final String hint;

  /// Подпись над полем.
  final String? label;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final String? prefixText;

  /// Устарело: опечатка сохранена для совместимости, используйте [maxLength].
  final int? maxLenth;
  final int? maxLength;

  /// Ошибка под полем. Не `null` → поле подсвечивается красным.
  final String? errorText;

  /// Подсказка под полем (показывается, когда нет [errorText]).
  final String? helperText;
  final IconData? prefixIcon;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  FocusNode? _internalFocus;
  bool _focused = false;

  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _internalFocus?.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    if (_focus.hasFocus != _focused) {
      setState(() => _focused = _focus.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final effectiveMaxLength = widget.maxLength ?? widget.maxLenth;

    final Color borderColor = !widget.enabled
        ? AppColors.border
        : hasError
        ? AppColors.error
        : _focused
        ? AppColors.primary
        : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: AppTypography.label),
          AppSpacing.gapXs,
        ],
        TextSelectionTheme(
          data: TextSelectionThemeData(
            cursorColor: AppColors.primary,
            selectionColor: AppColors.primary.withValues(alpha: 0.22),
            selectionHandleColor: AppColors.primary,
          ),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            decoration: BoxDecoration(
              color: widget.enabled
                  ? AppColors.surface
                  : AppColors.surfaceMuted,
              borderRadius: AppRadius.allMd,
              border: Border.all(
                color: borderColor,
                width: (_focused || hasError) ? 1.6 : 1,
              ),
              boxShadow: _focused ? AppShadows.card : AppShadows.none,
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              enabled: widget.enabled,
              autofocus: widget.autofocus,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              obscureText: widget.obscure,
              maxLength: effectiveMaxLength,
              maxLines: widget.obscure ? 1 : widget.maxLines,
              minLines: widget.minLines,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              inputFormatters: widget.inputFormatters,
              textCapitalization: widget.textCapitalization,
              autofillHints: widget.autofillHints,
              cursorColor: AppColors.primary,
              keyboardAppearance: Brightness.light,
              style: AppTypography.field.copyWith(
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTypography.fieldHint,
                isDense: true,
                filled: false,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                prefixIcon: widget.prefixIcon == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.md,
                          right: AppSpacing.xs,
                        ),
                        child: Icon(
                          widget.prefixIcon,
                          size: 20,
                          color: hasError
                              ? AppColors.error
                              : _focused
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                      ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
                prefixText: widget.prefixText,
                prefixStyle: AppTypography.field,
                suffixIcon: widget.suffix == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: widget.suffix,
                      ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xxs + 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: AppColors.error,
              ),
              AppSpacing.hGapXxs,
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: AppTypography.caption.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ] else if (widget.helperText != null &&
            widget.helperText!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs + 2),
          Text(widget.helperText!, style: AppTypography.captionMuted),
        ],
      ],
    );
  }
}
