import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';

/// Точка текущего местоположения пользователя на карте.
class MeDot extends StatelessWidget {
  const MeDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ваше местоположение',
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 3),
          boxShadow: AppShadows.raised,
        ),
      ),
    );
  }
}
