import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../data/model/delivery_point_model.dart';
import 'map_panel_shell.dart';

/// Панель «ищем исполнителя» над картой.
///
/// Маршрут показывается тем же компонентом [AppRoutePointTile], что и
/// в конструкторе маршрута и в итоговой карточке — раньше здесь был
/// собственный визуальный язык со стрелками вниз.
class SearchingSheet extends StatelessWidget {
  const SearchingSheet({
    super.key,
    required this.stops,
    required this.cancelling,
    required this.onCancel,
  });

  final List<DeliveryPoint> stops;
  final bool cancelling;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return MapPanelShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ищем исполнителя', style: AppTypography.cardTitle),
                    Text(
                      'Обычно это занимает несколько минут',
                      style: AppTypography.captionMuted,
                    ),
                  ],
                ),
              ),
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
              title: stops[i].title,
              subtitle: stops[i].subtitle,
              isLast: i == stops.length - 1,
              dense: true,
            ),
          AppSpacing.gapMd,
          AppSecondaryButton(
            label: 'Отменить поиск',
            loading: cancelling,
            danger: true,
            size: AppButtonSize.medium,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
