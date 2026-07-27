import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/utils/order_status_view.dart';

/// Вкладки фильтра списка заказов.
///
/// API постраничной выдачи `GET delivery/shipments/` не поддерживает
/// фильтрацию по статусу, поэтому фильтр применяется локально — только к уже
/// загруженным страницам. Схема запросов не менялась.
class OrderFilterTabs extends StatelessWidget {
  const OrderFilterTabs({
    super.key,
    required this.selected,
    required this.onChanged,
    this.counts = const {},
  });

  final OrderFilter selected;
  final ValueChanged<OrderFilter> onChanged;

  /// Количество загруженных заказов в каждой группе.
  final Map<OrderFilter, int> counts;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      child: Row(
        children: [
          for (final filter in OrderFilter.values) ...[
            if (filter != OrderFilter.values.first) AppSpacing.hGapXs,
            _Chip(
              label: filter.label,
              count: counts[filter],
              selected: filter == selected,
              onTap: () => onChanged(filter),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allFull,
        child: AnimatedContainer(
          duration: AppDurations.normal,
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: AppRadius.allFull,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: selected
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (count != null && count! > 0) ...[
                AppSpacing.hGapXxs,
                Text(
                  '$count',
                  style: AppTypography.badge.copyWith(
                    color: selected
                        ? AppColors.textOnPrimary.withValues(alpha: 0.8)
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
