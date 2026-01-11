import 'dart:async';
import 'package:finik_sdk/finik_sdk.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/finik_config.dart';
import '../../../../core/utils/app_colors.dart';
import '../provider/finik_payment_flow_provider.dart';

final class FinikPaymentScreen extends StatefulWidget {
  const FinikPaymentScreen({super.key});

  static const routeName = '/finik_pay';

  @override
  State<FinikPaymentScreen> createState() => _FinikPaymentScreenState();
}

class _FinikPaymentScreenState extends State<FinikPaymentScreen>
    with WidgetsBindingObserver {
  Timer? _resumeDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final flow = context.read<FinikPaymentFlowProvider>();
      if (flow.status == FinikFlowStatus.awaitingFinikUi) {
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _resumeDebounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    _resumeDebounce?.cancel();
    _resumeDebounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final flow = context.read<FinikPaymentFlowProvider>();

      if (flow.status == FinikFlowStatus.succeeded ||
          flow.status == FinikFlowStatus.failed) {
        return;
      }

      flow.startPollingPaid();
    });
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<FinikPaymentFlowProvider>();
    final init = flow.init;

    if (init == null || flow.shipmentId == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Text(
              flow.errorText ?? 'Платёж не инициализирован',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (FinikConfig.apiKey.isEmpty || FinikConfig.accountId.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Text(
              'Finik keys are empty.\nCheck assets/finik_key.env and dotenv.load() in main().',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final requiredFields = init.requiredFields.entries
        .map(
          (e) => RequiredField(
        fieldId: e.key,
        label: e.key,
        value: e.value?.toString(),
        isHidden: true,
      ),
    )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          FinikProvider(
            apiKey: FinikConfig.apiKey,
            isBeta: FinikConfig.isBeta,
            locale: FinikSdkLocale.RU,
            textScenario: TextScenario.PAYMENT,
            paymentMethods: const [PaymentMethod.APP, PaymentMethod.QR],
            enableShimmer: true,
            enableShare: true,
            enableSupportButtons: true,
            tapableSupportButtons: true,
            onBackPressed: () {
              context.read<FinikPaymentFlowProvider>().markFailed('Оплата отменена');
              if (Navigator.of(context).canPop()) Navigator.of(context).pop(false);
            },
            onPayment: (data) {
              final status = (data?['status'] ?? '').toString().toUpperCase();

              if (status == 'SUCCEEDED') {
                flow.startPollingPaid();
              } else if (status == 'FAILED') {
                flow.markFailed('Платёж отклонён');
                if (Navigator.of(context).canPop()) Navigator.of(context).pop(false);
              }
            },
            widget: CreateItemHandlerWidget(
              accountId: FinikConfig.accountId,
              nameEn: FinikConfig.itemNameEn,
              requestId: init.finikRequestId,
              amount: FixedAmount(init.amount.toDouble()),
              description: 'Shipment #${flow.shipmentId} (${init.currency})',
              callbackUrl: init.callbackUrl,
              requiredFields: requiredFields,
              visibilityType: VisibilityType.PRIVATE,
            ),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _FlowOverlayBar(),
          ),
        ],
      ),
    );
  }
}

class _FlowOverlayBar extends StatelessWidget {
  const _FlowOverlayBar();

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<FinikPaymentFlowProvider>();

    if (flow.status == FinikFlowStatus.succeeded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop(true);
      });
      return _bar('Оплата подтверждена',
          trailing: const Icon(Icons.check_circle, color: Colors.white));
    }

    if (flow.status == FinikFlowStatus.polling) {
      return _bar(
        'Подтверждаем оплату…',
        trailing: const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (flow.status == FinikFlowStatus.failed) {
      return _bar(flow.errorText ?? 'Ошибка оплаты',
          trailing: const Icon(Icons.error, color: Colors.white));
    }

    return const SizedBox.shrink();
  }

  static Widget _bar(String text, {Widget? trailing}) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing,
          ],
        ],
      ),
    );
  }
}
