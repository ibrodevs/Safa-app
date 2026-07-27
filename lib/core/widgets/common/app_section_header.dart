import 'package:flutter/material.dart';

import '../../design/app_design.dart';

/// Заголовок секции с опциональным описанием и действием справа.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && onAction != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.sectionTitle),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                AppSpacing.gapXxs,
                Text(subtitle!, style: AppTypography.caption),
              ],
            ],
          ),
        ),
        if (hasAction) ...[
          AppSpacing.hGapXs,
          Semantics(
            button: true,
            label: actionLabel,
            child: InkWell(
              onTap: onAction,
              borderRadius: AppRadius.allSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  actionLabel!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
