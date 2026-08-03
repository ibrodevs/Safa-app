import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';
import '../../data/model/delivery_refs_models.dart';

/// Маркер контейнера на карте.
///
/// Один компонент вместо двух разных реализаций в `map_screen`
/// и `map_picker_screen`.
///
/// * область нажатия — 44×44 px независимо от размера подписи;
/// * при большом количестве контейнеров (или малом масштабе) подпись
///   скрывается — остаётся компактная точка, чтобы карта не превращалась
///   в хаос;
/// * выбранный контейнер подсвечивается акцентным цветом и увеличенной
///   белой обводкой (не только цветом — размер тоже меняется).
class ContainerMapMarker extends StatelessWidget {
  const ContainerMapMarker({
    super.key,
    required this.container,
    required this.selected,
    this.onTap,
    this.showLabel = true,
  });

  /// Размер зоны нажатия маркера.
  static const double hitSize = 44;

  final ContainerRef container;
  final bool selected;
  final VoidCallback? onTap;

  /// Показывать номер контейнера. При `false` рисуется только точка.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: selected,
      label:
          'Контейнер ${container.number}'
          '${container.bazarName.isEmpty ? '' : ', ${container.bazarName}'}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: hitSize,
          height: hitSize,
          child: Center(
            child: showLabel || selected
                ? _LabelText(number: container.number, selected: selected)
                : const _Dot(),
          ),
        ),
      ),
    );
  }
}

class _LabelText extends StatelessWidget {
  const _LabelText({required this.number, required this.selected});

  final String number;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Text(
      number.isEmpty ? '•' : number,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: selected ? AppColors.primary : AppColors.textPrimary,
        fontSize: selected ? 13 : 12,
        height: 1,
        fontWeight: FontWeight.w800,
        shadows: const [
          Shadow(color: AppColors.white, blurRadius: 3),
          Shadow(color: AppColors.white, blurRadius: 6),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '•',
      style: TextStyle(
        fontFamily: AppTypography.fontFamily,
        color: AppColors.textPrimary,
        fontSize: 16,
        height: 1,
        fontWeight: FontWeight.w800,
        shadows: [
          Shadow(color: AppColors.white, blurRadius: 3),
          Shadow(color: AppColors.white, blurRadius: 6),
        ],
      ),
    );
  }
}
