import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

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

/// Текстовое поле в стиле полей щитов (иконка + рамка) с выпадающим
/// списком подсказок из справочника. Список появляется под полем при
/// фокусе и при вводе (с дебаунсом), ничего в существующем дизайне
/// не убирает — только добавляет подсказки.
class RefSuggestField<T> extends StatefulWidget {
  const RefSuggestField({
    super.key,
    required this.controller,
    required this.hint,
    required this.fetch,
    required this.onSelected,
    this.onTextEdited,
    this.height = 52,
    this.fillColor = Colors.white,
    this.radius = 16,
    this.horizontalPadding = 18,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w600,
    this.hintColor = const Color(0xFF9FA4AD),
    this.iconAsset = 'assets/icons/ic_box.svg',
  });

  final TextEditingController controller;
  final String hint;

  /// Загрузка подсказок по введённому тексту.
  final Future<List<RefSuggestion<T>>> Function(String query) fetch;

  /// Пользователь выбрал подсказку из списка.
  final ValueChanged<RefSuggestion<T>> onSelected;

  /// Пользователь изменил текст руками — выбранное ранее значение
  /// больше не актуально.
  final VoidCallback? onTextEdited;

  final double height;
  final Color fillColor;
  final double radius;
  final double horizontalPadding;
  final double fontSize;
  final FontWeight fontWeight;
  final Color hintColor;
  final String iconAsset;

  @override
  State<RefSuggestField<T>> createState() => _RefSuggestFieldState<T>();
}

class _RefSuggestFieldState<T> extends State<RefSuggestField<T>> {
  static const _accent = Color(0xFFFF8A00);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _greyText = Color(0xFF9FA4AD);

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
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focus.hasFocus) {
      setState(() => _open = true);
      _load(widget.controller.text);
    } else {
      // Небольшая задержка, чтобы успел сработать тап по подсказке.
      Future.delayed(const Duration(milliseconds: 200), () {
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
    } catch (_) {}

    if (!mounted || seq != _requestSeq) return;
    setState(() {
      _loading = false;
      _items = items;
    });
  }

  void _select(RefSuggestion<T> item) {
    _debounce?.cancel();
    widget.controller.text = item.fillText;
    widget.controller.selection =
        TextSelection.collapsed(offset: item.fillText.length);
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.fillColor,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(color: _tileBorder),
          ),
          padding:
              EdgeInsets.symmetric(horizontal: widget.horizontalPadding),
          child: Row(
            children: [
              SvgPicture.asset(
                widget.iconAsset,
                width: 20,
                height: 20,
                colorFilter:
                    const ColorFilter.mode(_accent, BlendMode.srcIn),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: widget.fontWeight,
                      color: widget.hintColor,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: widget.fontWeight,
                    color: Colors.black,
                  ),
                  cursorColor: Colors.black,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
        ),
        if (_open) _buildSuggestions(),
      ],
    );
  }

  Widget _buildSuggestions() {
    Widget child;
    if (_loading) {
      child = const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _accent,
            ),
          ),
        ),
      );
    } else if (_items.isEmpty) {
      child = const Padding(
        padding: EdgeInsets.all(14),
        child: Text(
          'Ничего не найдено',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _greyText,
          ),
        ),
      );
    } else {
      child = ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _items.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: _tileBorder),
        itemBuilder: (context, i) {
          final it = _items[i];
          return InkWell(
            onTap: () => _select(it),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    it.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (it.sublabel != null && it.sublabel!.isNotEmpty)
                    Text(
                      it.sublabel!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _greyText,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 216),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _tileBorder),
      ),
      child: child,
    );
  }
}
