import 'package:flutter/material.dart';

import '../../../../core/design/app_design.dart';
import '../../../../core/widgets/app_widgets.dart';

/// Шапка главного экрана: приветствие, имя, пояснение,
/// кнопка уведомлений и аватар-кнопка профиля.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.greeting,
    required this.prompt,
    this.avatarUrl,
    this.name,
    this.onNotifications,
    this.hasUnreadNotifications = false,
    this.onProfile,
  });

  final String greeting;

  /// Короткая подсказка о действии: «Куда отправим сегодня?».
  final String prompt;
  final String? avatarUrl;
  final String? name;
  final VoidCallback? onNotifications;
  final bool hasUnreadNotifications;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    final compact = AppResponsive.useCompactTitle(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: compact
                    ? AppTypography.screenTitleCompact
                    : AppTypography.screenTitle,
              ),
              AppSpacing.gapXxs,
              Text(prompt, style: AppTypography.bodySecondary),
            ],
          ),
        ),
        AppSpacing.hGapXs,
        if (onNotifications != null) ...[
          AppIconButton(
            icon: Icons.notifications_none_rounded,
            semanticLabel: 'Уведомления',
            onPressed: onNotifications,
            badge: hasUnreadNotifications,
          ),
          AppSpacing.hGapXs,
        ],
        AppAvatar(url: avatarUrl, name: name, onTap: onProfile),
      ],
    );
  }
}
