import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_widgets.dart';
import '../../../../data/services/logout_service.dart';

class CarrierLogoutButton extends StatelessWidget {
  const CarrierLogoutButton({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Выйти из аккаунта?',
      message: 'Вы сможете снова войти по номеру телефона и паролю.',
      confirmLabel: 'Выйти',
      cancelLabel: 'Остаться',
      danger: true,
      icon: Icons.logout_rounded,
    );

    if (!confirmed || !context.mounted) return;
    await const LogoutService().logout();
    if (!context.mounted) return;
    context.go('/select_role');
  }

  @override
  Widget build(BuildContext context) {
    return AppSecondaryButton(
      label: 'Выйти из аккаунта',
      icon: Icons.logout_rounded,
      danger: true,
      onPressed: () => _logout(context),
    );
  }
}
