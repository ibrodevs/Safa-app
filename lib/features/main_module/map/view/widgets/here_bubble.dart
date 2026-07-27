import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';
import 'parsed_adress.dart';

/// Подпись «Вы здесь» над маркером текущей геолокации.
///
/// Ширина ограничена сверху, но не задана жёстко, а текст переносится —
/// длинный адрес больше не обрезается посередине.
class HereBubble extends StatelessWidget {
  const HereBubble({
    super.key,
    this.onEdit,
    this.address,
    this.loading = false,
    this.marketTitle,
    this.detail,
    this.error,
  });

  final VoidCallback? onEdit;
  final String? address;
  final bool loading;
  final String? marketTitle;
  final String? detail;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final String titleLine;
    final String subtitleLine;

    if (loading) {
      titleLine = marketTitle ?? 'Определяем адрес…';
      subtitleLine = 'Уточняем ваше местоположение';
    } else if (error != null && error!.isNotEmpty) {
      titleLine = 'Адрес недоступен';
      subtitleLine = 'Проверьте интернет и попробуйте снова';
    } else if (address == null || address!.isEmpty) {
      titleLine = marketTitle ?? 'Адрес не найден';
      subtitleLine = 'Точка на карте';
    } else if (marketTitle != null || detail != null) {
      titleLine = marketTitle ?? 'Точка на карте';
      subtitleLine = detail ?? address!;
    } else {
      final parsed = parseAddressForUi(address);
      final resolvedTitle = parsed.marketTitle ?? 'Точка на карте';
      var resolvedSubtitle = parsed.detail ?? parsed.fullAfterCity;
      if (resolvedTitle == 'Точка на карте' && resolvedSubtitle.isEmpty) {
        resolvedSubtitle = address!;
      }
      titleLine = resolvedTitle;
      subtitleLine = resolvedSubtitle;
    }

    return Semantics(
      label: 'Вы здесь. $titleLine. $subtitleLine',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.allMd,
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.raised,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.my_location_rounded,
                    size: 12,
                    color: AppColors.primary,
                  ),
                  AppSpacing.hGapXxs,
                  Text(
                    'Вы здесь',
                    style: AppTypography.badge.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                titleLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitleLine.isNotEmpty)
                Text(
                  subtitleLine,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
