import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/widgets/app_widgets.dart';

/// Элемент подсказки для [RefSuggestField].
class RefSuggestion<T> {
  RefSuggestion({
    required this.label,
    required this.value,
    this.sublabel,
    String? fillText,
  }) : fillText = fillText ?? label;

  /// Основной текст в списке подсказок.
  final String label;

  /// Вторая строка (серым) в списке подсказок.
  final String? sublabel;

  /// Что подставить в поле при выборе (по умолчанию [label]).
  final String fillText;

  final T value;
}

/// Поле с подсказками из справочника (базары, проходы, контейнеры).
///
/// Логика загрузки сохранена: дебаунс 350 ms, отбрасывание устаревших ответов
/// по номеру запроса, задержка перед закрытием, чтобы успел сработать тап
/// по подсказке.
///
/// Изменено оформление: поле построено на [AppTextField], а список подсказок
/// ограничен по высоте и скроллится внутри себя, поэтому не выталкивает
/// содержимое формы за экран.
class RefSuggestField<T> extends StatefulWidget {
  const RefSuggestField({
    super.key,
    required this.controller,
    required this.hint,
    required this.fetch,
    required this.onSelected,
    this.label,
    this.onTextEdited,
    this.prefixIcon = Icons.storefront_outlined,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;

  /// Загрузка подсказок по введённому тексту.
  final Future<List<RefSuggestion<T>>> Function(String query) fetch;

  /// Пользователь выбрал подсказку из списка.
  final ValueChanged<RefSuggestion<T>> onSelected;

  /// Пользователь изменил текст руками — выбранное ранее значение
  /// больше не актуально.
  final VoidCallback? onTextEdited;

  final IconData prefixIcon;
  final bool enabled;

  @override
  State<RefSuggestField<T>> createState() => _RefSuggestFieldState<T>();
}

class _RefSuggestFieldState<T> extends State<RefSuggestField<T>> {
  final FocusNode _focus = FocusNode();
  Timer? _debounce;
  List<RefSuggestion<T>> _items = const [];
  bool _loading = false;
  bool _open = false;
  int _requestSeq = 0;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focus.hasFocus) {
      setState(() => _open = true);
      _load(widget.controller.text);
    } else {
      // Небольшая задержка, чтобы успел сработать тап по подсказке.
      Future.delayed(AppDurations.slow, () {
        if (mounted && !_focus.hasFocus) setState(() => _open = false);
      });
    }
  }

  void _onChanged(String text) {
    widget.onTextEdited?.call();
    _debounce?.cancel();
    if (!_open) setState(() => _open = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _load(text));
  }

  Future<void> _load(String q) async {
    final seq = ++_requestSeq;
    setState(() => _loading = true);

    List<RefSuggestion<T>> items = const [];
    try {
      items = await widget.fetch(q);
    } catch (_) {
      // Пустой список показывается как «Ничего не найдено».
    }

    if (!mounted || seq != _requestSeq) return;
    setState(() {
      _loading = false;
      _items = items;
    });
  }

  void _select(RefSuggestion<T> item) {
    _debounce?.cancel();
    widget.controller.text = item.fillText;
    widget.controller.selection = TextSelection.collapsed(
      offset: item.fillText.length,
    );
    setState(() {
      _open = false;
      _items = const [];
    });
    _focus.unfocus();
    widget.onSelected(item);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: widget.controller,
          focusNode: _focus,
          hint: widget.hint,
          label: widget.label,
          enabled: widget.enabled,
          prefixIcon: widget.prefixIcon,
          textInputAction: TextInputAction.next,
          onChanged: _onChanged,
        ),
        AnimatedSize(
          duration: AppDurations.fast,
          alignment: Alignment.topCenter,
          child: _open ? _buildSuggestions() : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    Widget child;

    if (_loading) {
      child = const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    } else if (_items.isEmpty) {
      child = Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Text('Ничего не найдено', style: AppTypography.captionMuted),
      );
    } else {
      child = ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _items.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (context, i) {
          final item = _items[i];
          return InkWell(
            onTap: () => _select(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs + 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.sublabel != null && item.sublabel!.isNotEmpty)
                    Text(
                      item.sublabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.captionMuted,
                    ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xxs + 2),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
