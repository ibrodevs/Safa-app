import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';

/// Общая оболочка для нижних панелей над картой (поиск исполнителя,
/// оплата, выполнение заказа).
///
/// Единые скругления, тень, ограничение высоты, прокрутка и безопасные
/// отступы — панели над картой больше не переполняются на маленьких экранах.
class MapPanelShell extends StatelessWidget {
  const MapPanelShell({
    super.key,
    required this.child,
    this.maxHeightFactor = 0.72,
  });

  final Widget child;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: media.size.height * maxHeightFactor,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.allXl,
          boxShadow: AppShadows.sheet,
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: child,
        ),
      ),
    );
  }
}
