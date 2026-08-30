import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../../services/service_config.dart';
import '../../data/model/delivery_point_model.dart';
import 'route_builder.dart';

/// Нижняя панель оформления заказа над картой.
///
/// Единый каркас для всех трёх сервисов: шапка сервиса, конструктор маршрута,
/// специфические поля сервиса и основная кнопка. Отличия описаны в
/// [ServiceConfig] — отдельных экранов для «Доставки», «Тачек» и «Аманата» нет.
class ServiceOrderPanel extends StatefulWidget {
  const ServiceOrderPanel({
    super.key,
    required this.config,
    required this.fromTitle,
    required this.fromSubtitle,
    required this.fromIsSelected,
    required this.destination,
    required this.intermediatePoints,
    required this.descriptionController,
    required this.creating,
    required this.onEditFrom,
    required this.onEditDestination,
    required this.onEditIntermediate,
    required this.onAddIntermediate,
    required this.onRemoveIntermediate,
    required this.onReorderIntermediate,
    required this.onSubmit,
    this.errorMessage,
    this.initiallyCollapsed = false,
    this.onCollapseChanged,
  });

  final ServiceConfig config;
  final String fromTitle;
  final String? fromSubtitle;
  final bool fromIsSelected;
  final DeliveryPoint? destination;
  final List<DeliveryPoint> intermediatePoints;

  /// Описание посылки для «Аманат» (существующее поле `description` API).
  final TextEditingController descriptionController;

  final bool creating;

  final VoidCallback onEditFrom;
  final VoidCallback onEditDestination;
  final void Function(int index) onEditIntermediate;
  final VoidCallback onAddIntermediate;
  final void Function(int index) onRemoveIntermediate;
  final void Function(int oldIndex, int newIndex) onReorderIntermediate;
  final VoidCallback onSubmit;

  final String? errorMessage;
  final bool initiallyCollapsed;
  final ValueChanged<bool>? onCollapseChanged;

  @override
  State<ServiceOrderPanel> createState() => _ServiceOrderPanelState();
}

class _ServiceOrderPanelState extends State<ServiceOrderPanel> {
  late bool _collapsed = widget.initiallyCollapsed;

  bool _hasRequiredDescription(String description) =>
      !widget.config.requiresDescription || description.trim().isNotEmpty;

  void _setCollapsed(bool val) {
    if (_collapsed == val) return;
    setState(() => _collapsed = val);
    widget.onCollapseChanged?.call(val);
  }

  void _toggleCollapse() {
    _setCollapsed(!_collapsed);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final safeBottom = media.viewPadding.bottom < 16
        ? 16.0
        : media.viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: _collapsed
              ? 160.0 + safeBottom
              : media.size.height * 0.78,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.sheetTop,
            boxShadow: AppShadows.sheet,
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragEnd: (details) {
                    final v = details.primaryVelocity ?? 0;
                    if (v > 150) {
                      _setCollapsed(true);
                    } else if (v < -150) {
                      _setCollapsed(false);
                    }
                  },
                  onTap: _toggleCollapse,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _Handle(),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: _ServiceHeader(
                          config: widget.config,
                          collapsed: _collapsed,
                          onToggle: _toggleCollapse,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_collapsed) ...[
                  AppSpacing.gapSm,
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RouteBuilder(
                            config: widget.config,
                            fromTitle: widget.fromTitle,
                            fromSubtitle: widget.fromSubtitle,
                            fromIsSelected: widget.fromIsSelected,
                            destination: widget.destination,
                            intermediatePoints: widget.intermediatePoints,
                            onEditFrom: widget.onEditFrom,
                            onEditDestination: widget.onEditDestination,
                            onEditIntermediate: widget.onEditIntermediate,
                            onAddIntermediate: widget.onAddIntermediate,
                            onRemoveIntermediate: widget.onRemoveIntermediate,
                            onReorderIntermediate: widget.onReorderIntermediate,
                          ),
                          if (widget.config.supportsDescription) ...[
                            AppSpacing.gapMd,
                            AppTextField(
                              controller: widget.descriptionController,
                              hint: widget.config.descriptionHint ?? '',
                              label: widget.config.descriptionLabel,
                              enabled: !widget.creating,
                              keyboardType: TextInputType.multiline,
                              maxLines: 3,
                              minLines: 2,
                              textInputAction: TextInputAction.newline,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: widget.descriptionController,
                    builder: (context, value, _) {
                      final hasDescription = _hasRequiredDescription(value.text);
                      final canSubmit = widget.destination != null &&
                          hasDescription &&
                          !widget.creating;

                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.md + safeBottom,
                        ),
                        child: Column(
                          children: [
                            AppFormError(message: widget.errorMessage),
                            if (widget.errorMessage != null) AppSpacing.gapSm,
                            AppPrimaryButton(
                              label: widget.config.primaryActionLabel,
                              loadingLabel: 'Создаём заказ…',
                              loading: widget.creating,
                              enabled: canSubmit,
                              onPressed: widget.onSubmit,
                            ),
                            if (widget.destination == null) ...[
                              AppSpacing.gapXs,
                              Text(
                                'Укажите ${widget.config.destinationLabel.toLowerCase()}, '
                                'чтобы продолжить',
                                textAlign: TextAlign.center,
                                style: AppTypography.captionMuted,
                              ),
                            ] else if (!hasDescription) ...[
                              AppSpacing.gapXs,
                              Text(
                                'Заполните ${widget.config.descriptionLabel?.toLowerCase() ?? 'описание'}, '
                                'чтобы продолжить',
                                textAlign: TextAlign.center,
                                style: AppTypography.captionMuted,
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ] else ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.md + safeBottom,
                    ),
                    child: InkWell(
                      borderRadius: AppRadius.allSm,
                      onTap: () => setState(() => _collapsed = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: widget.config.accentSoft,
                          borderRadius: AppRadius.allSm,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 16,
                              color: widget.config.accent,
                            ),
                            AppSpacing.hGapXs,
                            Expanded(
                              child: Text(
                                widget.destination != null
                                    ? '${widget.fromTitle} → ${widget.destination!.title}'
                                    : 'Нажмите или смахните вверх, чтобы указать адреса',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: widget.config.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 20,
                              color: widget.config.accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceHeader extends StatelessWidget {
  const _ServiceHeader({
    required this.config,
    this.collapsed = false,
    this.onToggle,
  });

  final ServiceConfig config;
  final bool collapsed;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: config.accentSoft,
            borderRadius: AppRadius.allXs,
          ),
          child: Icon(config.icon, size: 20, color: config.accent),
        ),
        AppSpacing.hGapXs,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(config.title, style: AppTypography.cardTitle),
              Text(
                config.orderSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionMuted,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onToggle,
          tooltip: collapsed ? 'Развернуть' : 'Свернуть',
          icon: Icon(
            collapsed
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.borderStrong,
          borderRadius: AppRadius.allFull,
        ),
      ),
    );
  }
}
