import 'package:flutter/material.dart';

import '../../../../core/design/app_design.dart';
import '../../../../core/utils/order_status_view.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../payments/data/repo/shipments_repository.dart';

/// Плашка активного заказа на главном экране.
///
/// Показывается только при реально загруженном активном заказе —
/// никаких заглушек и демо-данных.
class ActiveOrderBanner extends StatelessWidget {
  const ActiveOrderBanner({super.key, required this.shipment, this.onTap});

  final ShipmentsListItemDto shipment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = OrderStatusView.of(shipment.status);
    final stops = shipment.stops;
    final from = stops.isNotEmpty ? stops.first.title : null;
    final to = stops.length > 1 ? stops.last.title : null;

    return AppCard(
      onTap: onTap,
      color: AppColors.primarySoft,
      borderColor: AppColors.primary.withValues(alpha: 0.24),
      shadows: AppShadows.none,
      semanticLabel: 'Активный заказ. ${status.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Активный заказ №${shipment.id}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryPressed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppSpacing.hGapXs,
              status.toBadge(dense: true),
            ],
          ),
          AppSpacing.gapXs,
          if (from != null)
            Text(
              to == null ? from : '$from → $to',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.cardTitle,
            ),
          if (shipment.fare > 0) ...[
            const SizedBox(height: 2),
            Text(
              '${shipment.fare} сом',
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (shipment.carrierFirstName != null &&
              shipment.carrierFirstName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: (shipment.carrierAvatarUrl != null &&
                            shipment.carrierAvatarUrl!.isNotEmpty)
                        ? Image.network(
                            shipment.carrierAvatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              size: 14,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 14,
                            color: AppColors.primary,
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${shipment.carrierSpecialistType == "cart" ? "Тачкист" : "Специалист"}: ${shipment.carrierFirstName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (onTap != null) ...[
            AppSpacing.gapXs,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Открыть на карте',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primaryPressed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.primaryPressed,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
