import 'package:dogo/core/utils/styles.dart';
import 'package:flutter/material.dart';

class ClientTitleBlock extends StatelessWidget {
  const ClientTitleBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Кыргызский сервис\nнового поколения —',
          style: AppTextStyles.titleBlackStyle,
        ),
        const SizedBox(height: 12),
        Text(
          'Отслеживайте и узнавайте адреса \nактуальных складов  для доставки товаров',
          style: AppTextStyles.subtitleStyle,
        ),
      ],
    );
  }
}
