import 'package:flutter/material.dart';

import '../../design/app_design.dart';
import '../../utils/order_status_view.dart';
import 'app_card.dart';

/// Карточка заказа в списке.
///
/// Показывает номер, тип сервиса, статус, дату, начальную и конечную точки,
/// количество остановок, стоимость и одно короткое действие.
///
/// Все текстовые блоки переносятся и обрезаются по `ellipsis`, метаданные
/// разложены во `Wrap` — на 320 px и при системном масштабе 1.4 карточка
/// не переполняется.
class AppOrderCard extends StatelessWidget {
  const AppOrderCard({
    super.key,
    required this.number,
    required this.title,
    required this.status,
    this.serviceLabel,
    this.serviceIcon,
    this.date,
    this.fromTitle,
    this.toTitle,
    this.stopsCount,
    this.priceLabel,
    this.onTap,
    this.actionLabel = 'Подробнее',
  });

  final String number;
  final String title;
  final OrderStatusView status;
  final String? serviceLabel;
  final IconData? serviceIcon;
  final String? date;
  final String? fromTitle;
  final String? toTitle;
  final int? stopsCount;
  final String? priceLabel;
  final VoidCallback? onTap;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final meta = <Widget>[
      if (serviceLabel != null && serviceLabel!.isNotEmpty)
        _MetaItem(
          icon: serviceIcon ?? Icons.category_outlined,
          text: serviceLabel!,
        ),
      if (stopsCount != null && stopsCount! > 0)
        _MetaItem(
          icon: Icons.alt_route_rounded,
          text: 'Остановок: $stopsCount',
        ),
      if (priceLabel != null && priceLabel!.isNotEmpty)
        _MetaItem(
          icon: Icons.payments_outlined,
          text: priceLabel!,
          emphasize: true,
        ),
    ];

    return AppCard(
      onTap: onTap,
      semanticLabel: '$number. $title. ${status.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  number,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionMuted,
                ),
              ),
              AppSpacing.hGapXs,
              status.toBadge(dense: true),
            ],
          ),
          AppSpacing.gapXs,
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardTitle,
          ),
          if (date != null && date!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(date!, style: AppTypography.captionMuted),
          ],
          if (fromTitle != null || toTitle != null) ...[
            AppSpacing.gapSm,
            _RouteSummary(from: fromTitle, to: toTitle),
          ],
          if (meta.isNotEmpty) ...[
            AppSpacing.gapSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: meta,
            ),
          ],
          if (onTap != null) ...[
            AppSpacing.gapSm,
            const Divider(height: 1, color: AppColors.border),
            AppSpacing.gapXs,
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.from, required this.to});

  final String? from;
  final String? to;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (from != null && from!.isNotEmpty)
          _RouteLine(
            color: AppColors.success,
            text: from!,
            showConnector: to != null && to!.isNotEmpty,
          ),
        if (to != null && to!.isNotEmpty)
          _RouteLine(color: AppColors.primary, text: to!, showConnector: false),
      ],
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.color,
    required this.text,
    required this.showConnector,
  });

  final Color color;
  final String text;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            const SizedBox(height: 5),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            if (showConnector)
              Container(
                width: 2,
                height: 12,
                margin: const EdgeInsets.symmetric(vertical: 1),
                color: AppColors.border,
              ),
          ],
        ),
        AppSpacing.hGapXs,
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: showConnector ? AppSpacing.xxs : 0,
            ),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.text,
    this.emphasize = false,
  });

  final IconData icon;
  final String text;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: emphasize ? AppColors.primary : AppColors.textTertiary,
        ),
        AppSpacing.hGapXxs,
        Text(
          text,
          style: AppTypography.caption.copyWith(
            fontWeight: emphasize ? FontWeight.w600 : FontWeight.w500,
            color: emphasize ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
