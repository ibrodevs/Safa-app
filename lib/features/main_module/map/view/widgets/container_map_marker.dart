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
    final color = selected ? AppColors.primary : AppColors.container;

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
                ? _LabelBubble(
                    number: container.number,
                    color: color,
                    selected: selected,
                  )
                : _Dot(color: color),
          ),
        ),
      ),
    );
  }
}

class _LabelBubble extends StatelessWidget {
  const _LabelBubble({
    required this.number,
    required this.color,
    required this.selected,
  });

  final String number;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.fast,
      constraints: const BoxConstraints(minWidth: 26, maxWidth: 64),
      padding: EdgeInsets.symmetric(
        horizontal: selected ? 8 : 6,
        vertical: selected ? 5 : 4,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.allXs,
        border: Border.all(color: AppColors.white, width: selected ? 2.5 : 1.5),
        boxShadow: AppShadows.raised,
      ),
      child: Text(
        number.isEmpty ? '•' : number,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: AppColors.white,
          fontSize: 11,
          height: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 1.5),
      ),
    );
  }
}
