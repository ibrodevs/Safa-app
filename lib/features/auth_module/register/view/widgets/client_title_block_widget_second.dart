import 'package:dogo/core/utils/styles.dart';
import 'package:flutter/material.dart';

class ClientTitleBlockSecond extends StatelessWidget {
  const ClientTitleBlockSecond({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Регистрация',
          style: AppTextStyles.titleBlackStyle,
        ),
        Text(
          'Пройдите регистрацию для дальнейшего\nиспользования наших сервисов',
          style: AppTextStyles.subtitleStyle,
        ),
      ],
    );
  }
}
