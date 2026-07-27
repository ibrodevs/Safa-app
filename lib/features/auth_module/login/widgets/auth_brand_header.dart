import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/design/app_design.dart';

/// Шапка экранов авторизации: логотип, короткий заголовок, пояснение.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showLogo = true,
  });

  final String title;
  final String? subtitle;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final compact = AppResponsive.useCompactTitle(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLogo) ...[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppRadius.allMd,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              AppIcons.logo,
              width: 28,
              height: 28,
              colorFilter: const ColorFilter.mode(
                AppColors.primary,
                BlendMode.srcIn,
              ),
              placeholderBuilder: (_) => const Icon(
                Icons.local_shipping_rounded,
                size: 26,
                color: AppColors.primary,
              ),
            ),
          ),
          AppSpacing.gapLg,
        ],
        Text(
          title,
          style: compact
              ? AppTypography.screenTitleCompact
              : AppTypography.screenTitle,
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          AppSpacing.gapXs,
          Text(subtitle!, style: AppTypography.bodySecondary),
        ],
      ],
    );
  }
}
