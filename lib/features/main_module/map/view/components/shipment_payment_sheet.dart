import 'package:dogo/core/utils/app_colors.dart';
import 'package:dogo/features/main_module/payments/provider/finik_payment_flow_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';


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

  Future<void> _handlePay() async {
    if (_loading) return;

    setState(() => _loading = true);
    try {
      final flow = context.read<FinikPaymentFlowProvider>();
      await flow.startExistingShipmentPayment(widget.shipmentId);

      if (!mounted) return;

      final success = await GoRouter.of(context).pushNamed<bool>(
        'finik_pay',
      );

      if (success == true) {
        // Payment success logic handled by polling in MapScreen or Provider
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка инициализации оплаты: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      elevation: 20,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Тачкист найден!',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.green,
                          fontFamily: 'SFProDisplay',
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Заказ #${widget.shipmentId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey,
                          fontFamily: 'SFProText',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.green,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.tileBorder, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'К оплате',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  Text(
                    '${widget.amount} сом',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading ? null : _handlePay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Оплатить через Finik',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'SFProText',
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _loading ? null : widget.onCancel,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.cancelColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Отменить заказ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey2,
                    fontFamily: 'SFProText',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
