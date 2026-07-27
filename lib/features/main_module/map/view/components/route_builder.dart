import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../../services/service_config.dart';
import '../../data/model/delivery_point_model.dart';

/// Конструктор маршрута — общий каркас для всех трёх сервисов.
///
/// Порядок точек и формат передачи на backend не меняются:
/// `[начальная, ...промежуточные, конечная]`.
///
/// Различия между сервисами берутся из [ServiceConfig]:
/// * «Доставка» и «Аманат» — две точки, кнопка добавления остановки скрыта;
/// * «Тачки» — промежуточные точки можно добавлять, удалять и
///   переупорядочивать через [ReorderableListView].
///
/// Начальную и конечную точки удалить нельзя.
class RouteBuilder extends StatelessWidget {
  const RouteBuilder({
    super.key,
    required this.config,
    required this.fromTitle,
    required this.fromSubtitle,
    required this.fromIsSelected,
    required this.destination,
    required this.intermediatePoints,
    required this.onEditFrom,
    required this.onEditDestination,
    required this.onEditIntermediate,
    required this.onAddIntermediate,
    required this.onRemoveIntermediate,
    required this.onReorderIntermediate,
  });

  final ServiceConfig config;

  /// Заголовок начальной точки (адрес по GPS или выбранная точка).
  final String fromTitle;
  final String? fromSubtitle;

  /// Начальная точка выбрана пользователем вручную (а не взята из GPS).
  final bool fromIsSelected;

  final DeliveryPoint? destination;
  final List<DeliveryPoint> intermediatePoints;

  final VoidCallback onEditFrom;
  final VoidCallback onEditDestination;
  final void Function(int index) onEditIntermediate;
  final VoidCallback onAddIntermediate;
  final void Function(int index) onRemoveIntermediate;
  final void Function(int oldIndex, int newIndex) onReorderIntermediate;

  bool get _canAddMore =>
      config.allowsIntermediateStops &&
      (config.maxIntermediateStops == 0 ||
          intermediatePoints.length < config.maxIntermediateStops);

  @override
  Widget build(BuildContext context) {
    final stops = intermediatePoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppRoutePointTile(
          role: RoutePointRole.start,
          title: fromTitle,
          subtitle: fromSubtitle,
          placeholder: !fromIsSelected,
          dense: true,
          onTap: onEditFrom,
        ),
        if (config.allowsIntermediateStops && stops.isNotEmpty)
          _IntermediateList(
            points: stops,
            onEdit: onEditIntermediate,
            onRemove: onRemoveIntermediate,
            onReorder: onReorderIntermediate,
          ),
        AppRoutePointTile(
          role: RoutePointRole.end,
          title: destination?.title ?? config.destinationHint,
          subtitle: destination?.subtitle,
          placeholder: destination == null,
          dense: true,
          isLast: true,
          onTap: onEditDestination,
        ),
        if (config.allowsIntermediateStops) ...[
          AppSpacing.gapSm,
          AppSecondaryButton(
            label: _canAddMore
                ? '+ Добавить остановку'
                : 'Достигнут лимит остановок',
            accent: true,
            size: AppButtonSize.small,
            enabled: _canAddMore,
            onPressed: onAddIntermediate,
          ),
          if (stops.length > 1) ...[
            AppSpacing.gapXs,
            Text(
              'Удерживайте остановку, чтобы изменить её порядок',
              textAlign: TextAlign.center,
              style: AppTypography.captionMuted,
            ),
          ],
        ],
      ],
    );
  }
}

class _IntermediateList extends StatelessWidget {
  const _IntermediateList({
    required this.points,
    required this.onEdit,
    required this.onRemove,
    required this.onReorder,
  });

  final List<DeliveryPoint> points;
  final void Function(int index) onEdit;
  final void Function(int index) onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

  @override
  Widget build(BuildContext context) {
    // Список остановок держим внутри ограниченной по высоте области:
    // панель над картой не должна расти бесконечно.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const ClampingScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: points.length,
        onReorder: onReorder,
        proxyDecorator: (child, index, animation) => Material(
          color: AppColors.surface,
          borderRadius: AppRadius.allSm,
          elevation: 2,
          shadowColor: AppColors.scrim,
          child: child,
        ),
        itemBuilder: (context, index) {
          final point = points[index];
          return Padding(
            key: ValueKey('stop-${point.title}-$index'),
            padding: EdgeInsets.zero,
            child: AppRoutePointTile(
              role: RoutePointRole.stop,
              index: index + 1,
              title: point.title,
              subtitle: point.subtitle,
              dense: true,
              onTap: () => onEdit(index),
              onRemove: () => onRemove(index),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Icon(
                          Icons.drag_handle_rounded,
                          size: 20,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Удалить остановку ${index + 1}',
                    child: InkWell(
                      onTap: () => onRemove(index),
                      borderRadius: AppRadius.allFull,
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
