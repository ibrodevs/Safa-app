import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../../services/service_config.dart';
import '../../data/model/delivery_refs_models.dart';

/// Какую роль в маршруте назначить выбранному контейнеру.
enum ContainerAssignment { from, destination, intermediate }

/// Карточка выбранного на карте контейнера.
///
/// Показывает тип объекта, базар, номер контейнера и проход, а затем
/// позволяет назначить его точкой отправки, точкой доставки или
/// (для «Тачек») промежуточной остановкой.
///
/// Раньше выбрать контейнер прямо на главной карте было нельзя:
/// маркер имел только `Tooltip` и не реагировал на нажатие.
class ContainerDetailsSheet extends StatelessWidget {
  const ContainerDetailsSheet({
    super.key,
    required this.container,
    required this.config,
  });

  final ContainerRef container;
  final ServiceConfig config;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'Контейнер ${container.number}',
      subtitle: 'Объект из справочника базаров',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: AppRadius.allMd,
            ),
            child: Column(
              children: [
                _Row(
                  icon: Icons.storefront_outlined,
                  label: 'Базар',
                  value: container.bazarName.trim().isEmpty
                      ? '—'
                      : container.bazarName.trim(),
                ),
                _Row(
                  icon: Icons.linear_scale_rounded,
                  label: 'Проход',
                  value: container.passageNumber.trim().isEmpty
                      ? '—'
                      : container.passageNumber.trim(),
                ),
                _Row(
                  icon: Icons.inventory_2_outlined,
                  label: 'Контейнер',
                  value: container.number.trim().isEmpty
                      ? '—'
                      : container.number.trim(),
                ),
                _Row(
                  icon: Icons.my_location_rounded,
                  label: 'Координаты',
                  value:
                      (container.latValue == null || container.lonValue == null)
                      ? 'Недоступны'
                      : '${container.latValue!.toStringAsFixed(5)}, '
                            '${container.lonValue!.toStringAsFixed(5)}',
                  isLast: true,
                ),
              ],
            ),
          ),
          AppSpacing.gapLg,
          Text('Использовать как', style: AppTypography.label),
          AppSpacing.gapXs,
          AppPrimaryButton(
            label:
                'Выбрать контейнер как ${config.destinationLabel.toLowerCase()}',
            size: AppButtonSize.medium,
            onPressed: () =>
                Navigator.of(context).pop(ContainerAssignment.destination),
          ),
          AppSpacing.gapXs,
          AppSecondaryButton(
            label: 'Точка отправки',
            size: AppButtonSize.medium,
            onPressed: () =>
                Navigator.of(context).pop(ContainerAssignment.from),
          ),
          if (config.allowsIntermediateStops) ...[
            AppSpacing.gapXs,
            AppSecondaryButton(
              label: 'Подтвердить остановку',
              accent: true,
              size: AppButtonSize.medium,
              onPressed: () =>
                  Navigator.of(context).pop(ContainerAssignment.intermediate),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          AppSpacing.hGapXs,
          Expanded(child: Text(label, style: AppTypography.caption)),
          AppSpacing.hGapXs,
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
