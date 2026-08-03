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
class ServiceOrderPanel extends StatelessWidget {
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

  bool _hasRequiredDescription(String description) =>
      !config.requiresDescription || description.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final safeBottom = media.viewPadding.bottom;

    // Панель никогда не занимает больше 78% экрана и всегда поднимается
    // над клавиатурой — при вводе описания «Аманата» кнопка остаётся видимой.
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.78),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.sheetTop,
            boxShadow: AppShadows.sheet,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Handle(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _ServiceHeader(config: config),
              ),
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
                        config: config,
                        fromTitle: fromTitle,
                        fromSubtitle: fromSubtitle,
                        fromIsSelected: fromIsSelected,
                        destination: destination,
                        intermediatePoints: intermediatePoints,
                        onEditFrom: onEditFrom,
                        onEditDestination: onEditDestination,
                        onEditIntermediate: onEditIntermediate,
                        onAddIntermediate: onAddIntermediate,
                        onRemoveIntermediate: onRemoveIntermediate,
                        onReorderIntermediate: onReorderIntermediate,
                      ),
                      if (config.supportsDescription) ...[
                        AppSpacing.gapMd,
                        AppTextField(
                          controller: descriptionController,
                          hint: config.descriptionHint ?? '',
                          label: config.descriptionLabel,
                          enabled: !creating,
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
                valueListenable: descriptionController,
                builder: (context, value, _) {
                  final hasDescription = _hasRequiredDescription(value.text);
                  final canSubmit =
                      destination != null && hasDescription && !creating;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.md + safeBottom,
                    ),
                    child: Column(
                      children: [
                        AppFormError(message: errorMessage),
                        if (errorMessage != null) AppSpacing.gapSm,
                        AppPrimaryButton(
                          label: config.primaryActionLabel,
                          loadingLabel: 'Создаём заказ…',
                          loading: creating,
                          enabled: canSubmit,
                          onPressed: onSubmit,
                        ),
                        if (destination == null) ...[
                          AppSpacing.gapXs,
                          Text(
                            'Укажите ${config.destinationLabel.toLowerCase()}, '
                            'чтобы продолжить',
                            textAlign: TextAlign.center,
                            style: AppTypography.captionMuted,
                          ),
                        ] else if (!hasDescription) ...[
                          AppSpacing.gapXs,
                          Text(
                            'Заполните ${config.descriptionLabel?.toLowerCase() ?? 'описание'}, '
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
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceHeader extends StatelessWidget {
  const _ServiceHeader({required this.config});

  final ServiceConfig config;

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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionMuted,
              ),
            ],
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
