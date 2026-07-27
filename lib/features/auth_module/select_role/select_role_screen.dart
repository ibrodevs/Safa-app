import 'package:dogo/core/design/app_design.dart';
import 'package:dogo/core/widgets/app_widgets.dart';
import 'package:dogo/features/auth_module/register/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../login/widgets/auth_brand_header.dart';
import '../register/data/models/register_request_model.dart';
import '../register/view/components/register_dots_indicator.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key, this.onTapClient, this.onTapCarrier});

  final VoidCallback? onTapClient;
  final VoidCallback? onTapCarrier;

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      backgroundColor: AppColors.surface,
      footer: Column(
        children: [
          const Hero(
            tag: 'register_dots',
            child: RegisterDotsIndicator(activeIndex: 0),
          ),
          AppTextButton(
            label: 'Уже есть аккаунт? Войти',
            onPressed: () => context.push('/login'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AuthBrandHeader(
            title: 'Кыргызский сервис нового поколения',
            subtitle: 'Доставка, тачки и аманат — всё в одном приложении',
          ),
          AppSpacing.gapXl,
          const AppSectionHeader(
            title: 'Кто вы?',
            subtitle: 'От этого зависит, какие возможности будут доступны',
          ),
          AppSpacing.gapSm,
          _RoleCard(
            imageAsset: AppImages.roleClient,
            icon: Icons.shopping_bag_outlined,
            title: 'Я клиент',
            subtitle:
                'Оформляйте доставку, тачки и аманат '
                'и следите за статусом заказа',
            onTap:
                onTapClient ??
                () {
                  context.read<AuthProvider>().setRole(UserRole.client);
                  context.push('/register-client');
                },
          ),
          AppSpacing.gapSm,
          _RoleCard(
            imageAsset: AppImages.roleCarrier,
            icon: Icons.local_shipping_outlined,
            title: 'Я специалист',
            subtitle: 'Принимайте заказы поблизости и выполняйте маршруты',
            onTap:
                onTapCarrier ??
                () {
                  context.read<AuthProvider>().setRole(UserRole.carrier);
                  context.push('/register-carrier');
                },
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.imageAsset,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String imageAsset;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Картинка появляется только там, где для неё реально есть место:
    // раньше фиксированный блок 110 px рядом с Expanded-текстом
    // переполнял Row на 320 px.
    final showImage = !AppResponsive.isCompact(context);

    return AppCard(
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      child: Row(
        children: [
          if (showImage)
            ClipRRect(
              borderRadius: AppRadius.allMd,
              child: Image.asset(
                imageAsset,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _IconBox(icon: icon),
              ),
            )
          else
            _IconBox(icon: icon),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          AppSpacing.hGapXxs,
          const Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppRadius.allMd,
      ),
      child: Icon(icon, size: 24, color: AppColors.primary),
    );
  }
}
