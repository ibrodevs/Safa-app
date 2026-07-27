import 'package:flutter/material.dart';

import '../../design/app_design.dart';
import 'app_card.dart';

/// Карточка сервиса на главном экране.
///
/// Все три сервиса («Доставка», «Тачки», «Аманат») используют **один**
/// компонент. Различаются только иконка, оттенок подложки иконки, картинка
/// и тексты — раньше это были два разных виджета с разной вёрсткой.
///
/// Адаптивность: на экранах уже 360 px картинка скрывается, а текст получает
/// всю ширину, поэтому `Row` не переполняется на 320 px.
class AppServiceCard extends StatelessWidget {
  const AppServiceCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.accent = AppColors.primary,
    this.accentSoft = AppColors.primarySoft,
    this.imageAsset,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  /// Небольшое различие между сервисами — цвет иконки.
  final Color accent;
  final Color accentSoft;
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    final compact = AppResponsive.isCompact(context);
    final showImage = imageAsset != null && !compact;

    return AppCard(
      onTap: onTap,
      semanticLabel: '$title. $description',
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentSoft,
              borderRadius: AppRadius.allMd,
            ),
            child: Icon(icon, size: 24, color: accent),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text(description, style: AppTypography.caption),
              ],
            ),
          ),
          if (showImage) ...[
            AppSpacing.hGapXs,
            SizedBox(
              width: 56,
              height: 48,
              child: Image.asset(
                imageAsset!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
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
