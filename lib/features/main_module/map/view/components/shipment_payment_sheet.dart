import 'package:dogo/features/main_module/payments/provider/finik_payment_flow_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/utils/friendly_error.dart';
import '../../../../../core/widgets/app_widgets.dart';
import 'map_panel_shell.dart';

/// Панель оплаты найденного заказа.
///
/// Логика оплаты через Finik не изменена: `startExistingShipmentPayment`
/// и переход на именованный маршрут `finik_pay`. Изменилось только
/// оформление и обработка ошибки — вместо `Ошибка инициализации оплаты: $e`
/// пользователь видит человекочитаемый текст.
class ShipmentPaymentSheet extends StatefulWidget {
  const ShipmentPaymentSheet({
    super.key,
    required this.shipmentId,
    required this.amount,
    required this.onCancel,
  });

  final int shipmentId;
  final int amount;
  final VoidCallback onCancel;

  @override
  State<ShipmentPaymentSheet> createState() => _ShipmentPaymentSheetState();
}

class _ShipmentPaymentSheetState extends State<ShipmentPaymentSheet> {
  bool _loading = false;
  String? _error;

  Future<void> _handlePay() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final flow = context.read<FinikPaymentFlowProvider>();
      await flow.startExistingShipmentPayment(widget.shipmentId);

      if (!mounted) return;

      // Результат оплаты подхватывается поллингом статуса заказа.
      await GoRouter.of(context).pushNamed<bool>('finik_pay');
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = friendlyErrorMessage(
          e,
          fallback: 'Не удалось начать оплату. Попробуйте ещё раз.',
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapPanelShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.successSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Исполнитель найден', style: AppTypography.cardTitle),
                    Text(
                      'Заказ №${widget.shipmentId}',
                      style: AppTypography.captionMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapMd,
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: AppRadius.allMd,
            ),
            child: Row(
              children: [
                Expanded(child: Text('К оплате', style: AppTypography.body)),
                Text(
                  '${widget.amount} сом',
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.gapMd,
          AppFormError(message: _error),
          if (_error != null) AppSpacing.gapSm,
          AppPrimaryButton(
            label: 'Оплатить через Finik',
            loadingLabel: 'Открываем оплату…',
            loading: _loading,
            size: AppButtonSize.medium,
            onPressed: _handlePay,
          ),
          AppSpacing.gapXs,
          AppSecondaryButton(
            label: 'Отменить заказ',
            danger: true,
            size: AppButtonSize.medium,
            enabled: !_loading,
            onPressed: widget.onCancel,
          ),
        ],
      ),
    );
  }
}
