import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/utils/order_status_view.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../data/model/delivery_point_model.dart';
import 'map_panel_shell.dart';

/// Панель «заказ выполняется» над картой.
class OrderFulfillmentSheet extends StatelessWidget {
  const OrderFulfillmentSheet({
    super.key,
    required this.stops,
    this.statusCode = 'in_transit',
  });

  final List<DeliveryPoint> stops;

  /// Код статуса с backend — определяет текст и цвет бейджа.
  final String statusCode;

  String _titleForStop(DeliveryPoint s) {
    final container = (s.container ?? '').trim();
    final passage = (s.passage ?? '').trim();

    if (container.isNotEmpty && passage.isNotEmpty) {
      return 'Контейнер $container, проход $passage';
    }
    if (container.isNotEmpty) return 'Контейнер $container';
    if (passage.isNotEmpty) return 'Проход $passage';

    return s.title;
  }

  String _subtitleForStop(DeliveryPoint s) {
    final bazar = (s.bazar ?? '').trim();
    return bazar.isNotEmpty ? bazar : s.subtitle;
  }

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();

    final status = OrderStatusView.of(statusCode);

    return MapPanelShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Заказ выполняется',
                  style: AppTypography.cardTitle,
                ),
              ),
              AppSpacing.hGapXs,
              status.toBadge(dense: true),
            ],
          ),
          AppSpacing.gapMd,
          for (var i = 0; i < stops.length; i++)
            AppRoutePointTile(
              role: i == 0
                  ? RoutePointRole.start
                  : i == stops.length - 1
                  ? RoutePointRole.end
                  : RoutePointRole.stop,
              index: (i > 0 && i < stops.length - 1) ? i : null,
              title: _titleForStop(stops[i]),
              subtitle: _subtitleForStop(stops[i]),
              isLast: i == stops.length - 1,
              dense: true,
              trailing: i == 0
                  ? const AppStatusBadge(
                      label: 'Вы здесь',
                      tone: AppBadgeTone.success,
                      icon: Icons.person_pin_circle_outlined,
                      dense: true,
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
