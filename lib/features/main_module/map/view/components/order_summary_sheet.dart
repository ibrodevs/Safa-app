import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/utils/friendly_error.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../../payments/data/repo/shipments_repository.dart';
import '../../../services/service_config.dart';
import '../../data/model/delivery_point_model.dart';

/// Итоговая карточка заказа перед отправкой.
///
/// Показывает маршрут, число точек, выбранный сервис, стоимость,
/// способ оплаты, дополнительные параметры и предупреждение,
/// если данных недостаточно.
///
/// Стоимость берётся из уже существующего эндпоинта
/// `POST delivery/shipments/quote/` — новых полей API не появляется.
/// Если расчёт недоступен, карточка не блокирует оформление: показывается
/// «Стоимость уточнит исполнитель».
class OrderSummarySheet extends StatefulWidget {
  const OrderSummarySheet({
    super.key,
    required this.config,
    required this.stops,
    required this.description,
    required this.onConfirm,
    this.repository,
  });

  final ServiceConfig config;

  /// Точки в том же порядке, в котором уйдут на backend.
  final List<DeliveryPoint> stops;

  /// Описание для «Аманат» (существующее поле `description`).
  final String description;

  /// Возвращает текст ошибки, если создать заказ не удалось,
  /// и `null` при успехе.
  final Future<String?> Function() onConfirm;

  final ShipmentsRepository? repository;

  @override
  State<OrderSummarySheet> createState() => _OrderSummarySheetState();
}

class _OrderSummarySheetState extends State<OrderSummarySheet> {
  late final ShipmentsRepository _repo =
      widget.repository ?? ShipmentsRepository();

  bool _quoteLoading = false;
  int? _quoteAmount;
  bool _quoteUnavailable = false;

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuote());
  }

  bool get _hasMissingCoordinates =>
      widget.stops.any((s) => s.lat == null || s.lon == null);

  Future<void> _loadQuote() async {
    if (_hasMissingCoordinates) {
      setState(() => _quoteUnavailable = true);
      return;
    }

    setState(() {
      _quoteLoading = true;
      _quoteUnavailable = false;
    });

    try {
      final quote = await _repo.getQuote(
        stops: widget.stops.map((s) => s.toStopJson()).toList(),
      );
      if (!mounted) return;

      final raw = quote['estimated_fare'] ?? quote['fare'] ?? quote['amount'];
      final amount = raw is num
          ? raw.toInt()
          : int.tryParse(raw?.toString() ?? '');

      setState(() {
        _quoteLoading = false;
        _quoteAmount = (amount != null && amount > 0) ? amount : null;
        _quoteUnavailable = _quoteAmount == null;
      });
    } catch (_) {
      if (!mounted) return;
      // Недоступный расчёт не мешает оформить заказ.
      setState(() {
        _quoteLoading = false;
        _quoteUnavailable = true;
      });
    }
  }

  Future<void> _confirm() async {
    if (_submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = await widget.onConfirm();

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _submitting = false;
      _error = friendlyErrorMessage(error, fallback: error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stops = widget.stops;
    final intermediateCount = stops.length > 2 ? stops.length - 2 : 0;

    return AppBottomSheet(
      title: 'Проверьте заказ',
      subtitle:
          '${widget.config.title} · ${stops.length} '
          '${_pointsWord(stops.length)}',
      footer: Column(
        children: [
          AppFormError(message: _error),
          if (_error != null) AppSpacing.gapSm,
          AppPrimaryButton(
            label: widget.config.primaryActionLabel,
            loadingLabel: 'Создаём заказ…',
            loading: _submitting,
            enabled: !_hasMissingCoordinates,
            onPressed: _confirm,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasMissingCoordinates) ...[
            const _Warning(
              text:
                  'У некоторых точек нет координат. Выберите контейнер '
                  'из справочника или укажите место на карте.',
            ),
            AppSpacing.gapMd,
          ],
          _SummaryCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
              ],
            ),
          ),
          AppSpacing.gapMd,
          _SummaryCard(
            child: Column(
              children: [
                _SummaryRow(
                  icon: widget.config.icon,
                  label: 'Сервис',
                  value: widget.config.title,
                ),
                if (intermediateCount > 0)
                  _SummaryRow(
                    icon: Icons.alt_route_rounded,
                    label: 'Остановок в пути',
                    value: '$intermediateCount',
                  ),
                _SummaryRow(
                  icon: Icons.payments_outlined,
                  label: 'Стоимость',
                  value: _quoteLoading
                      ? 'Считаем…'
                      : _quoteAmount != null
                      ? '${_quoteAmount!} сом'
                      : 'Уточнит исполнитель',
                  emphasize: _quoteAmount != null,
                ),
                _SummaryRow(
                  icon: Icons.credit_card_outlined,
                  label: 'Оплата',
                  value: 'После назначения исполнителя',
                ),
                if (widget.config.supportsDescription &&
                    widget.description.trim().isNotEmpty)
                  _SummaryRow(
                    icon: Icons.description_outlined,
                    label: widget.config.descriptionLabel ?? 'Описание',
                    value: widget.description.trim(),
                    isLast: true,
                  ),
              ],
            ),
          ),
          if (_quoteUnavailable && !_hasMissingCoordinates) ...[
            AppSpacing.gapSm,
            Text(
              'Предварительный расчёт недоступен — итоговую сумму '
              'подтвердит исполнитель.',
              style: AppTypography.captionMuted,
            ),
          ],
        ],
      ),
    );
  }

  static String _pointsWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'точка';
    if ([2, 3, 4].contains(count % 10) &&
        !(count % 100 >= 12 && count % 100 <= 14)) {
      return 'точки';
    }
    return 'точек';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;
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
              style: AppTypography.caption.copyWith(
                color: emphasize ? AppColors.primary : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: AppRadius.allSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.warning,
          ),
          AppSpacing.hGapXs,
          Expanded(child: Text(text, style: AppTypography.caption)),
        ],
      ),
    );
  }
}
