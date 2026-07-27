import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/widgets/app_widgets.dart';

/// Лист, который показывается клиенту, когда заказ завершён.
class OrderCompletedSheet extends StatelessWidget {
  const OrderCompletedSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      showCloseButton: false,
      footer: AppPrimaryButton(
        label: 'Отлично',
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSpacing.gapSm,
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.successSoft,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 36,
              color: AppColors.success,
            ),
          ),
          AppSpacing.gapMd,
          Text(
            'Заказ завершён',
            textAlign: TextAlign.center,
            style: AppTypography.sectionTitle,
          ),
          AppSpacing.gapXs,
          Text(
            'Исполнитель доставил ваш заказ. '
            'Спасибо, что пользуетесь Safa App!',
            textAlign: TextAlign.center,
            style: AppTypography.bodySecondary,
          ),
        ],
      ),
    );
  }
}
