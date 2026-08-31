import 'dart:async';
import 'dart:ui';

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
  FinikPaymentFlowProvider? _flow;
  Timer? _resumeDebounce;
  Timer? _successCloseTimer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextFlow = context.read<FinikPaymentFlowProvider>();
    if (identical(_flow, nextFlow)) return;

    _flow?.removeListener(_handleFlowStatusChanged);
    _flow = nextFlow..addListener(_handleFlowStatusChanged);
    _handleFlowStatusChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flow?.removeListener(_handleFlowStatusChanged);
    _resumeDebounce?.cancel();
    _successCloseTimer?.cancel();
    super.dispose();
  }

  void _handleFlowStatusChanged() {
    if (!mounted || _closing) return;

    if (_flow?.status == FinikFlowStatus.succeeded) {
      _successCloseTimer ??= Timer(
        const Duration(milliseconds: 1400),
        () => _finishPayment(true),
      );
      return;
    }

    _successCloseTimer?.cancel();
    _successCloseTimer = null;
  }

  void _finishPayment(bool paid) {
    if (!mounted || _closing) return;
    _closing = true;
    _resumeDebounce?.cancel();
    _successCloseTimer?.cancel();

    // FinikProvider is an InheritedWidget. Removing its route directly from a
    // callback of one of its descendants can leave registered dependants in
    // the tree until the current frame finishes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) navigator.pop(paid);
    });
  }

  void _handleFinikBack() {
    _flow?.markFailed('Оплата отменена');
    _finishPayment(false);
  }

  void _handleFinikPayment(Map<String, dynamic>? data) {
    // A rejected payment remains on this route so the error overlay can be
    // rendered before the user returns. This also avoids popping the Finik
    // inherited subtree from inside its notification callback.
    _flow?.handlePaymentResult(data);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    _resumeDebounce?.cancel();
    _resumeDebounce = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final flow = _flow;
      if (flow == null) return;

      if (flow.status == FinikFlowStatus.succeeded ||
          flow.status == FinikFlowStatus.failed) {
        return;
      }

      flow.startPollingPaid();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Do not watch the flow here: status updates must rebuild only the overlay,
    // not FinikProvider and the SDK subtree below it.
    final flow = _flow ?? context.read<FinikPaymentFlowProvider>();
    final init = flow.init;

    if (init == null || !flow.hasPaymentTarget) {
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

    if (FinikConfig.apiKey.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Text(
              'Finik не настроен. Передайте FINIK_API_KEY через --dart-define.',
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
            onBackPressed: _handleFinikBack,
            onPayment: _handleFinikPayment,
            widget: CreateItemHandlerWidget(
              accountId: AccountId(init.accountId),
              nameEn: FinikConfig.itemNameEn,
              requestId: init.finikRequestId,
              amount: FixedAmount(init.amount.toDouble()),
              description: '${flow.paymentDescription} (${init.currency})',
              callbackUrl: init.callbackUrl,
              maxAvailableQuantity: 1,
              requiredFields: requiredFields,
              visibilityType: VisibilityType.PRIVATE,
              onCreated: flow.recordCreatedItem,
            ),
          ),
          Positioned.fill(
            child: _FinikStatusOverlay(
              onDone: () => _finishPayment(true),
              onBack: () => _finishPayment(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinikStatusOverlay extends StatelessWidget {
  const _FinikStatusOverlay({required this.onDone, required this.onBack});

  final VoidCallback onDone;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<FinikPaymentFlowProvider>();
    final status = flow.status;

    if (status != FinikFlowStatus.polling &&
        status != FinikFlowStatus.succeeded &&
        status != FinikFlowStatus.failed) {
      return const SizedBox.shrink();
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8 * value, sigmaY: 8 * value),
            child: Container(
              color: AppColors.black.withValues(alpha: 0.4 * value),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: status == FinikFlowStatus.polling
                      ? _buildPollingCard()
                      : status == FinikFlowStatus.succeeded
                      ? _buildSuccessCard(flow.successMessage)
                      : _buildFailedCard(flow.errorText),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPollingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 64,
            width: 64,
            child: CircularProgressIndicator(
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              strokeCap: StrokeCap.round,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Проверка платежа',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
              fontFamily: 'SFProDisplay',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Обычно это занимает пару секунд. Не закрывайте приложение…',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.grey2.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(String successMessage) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 24),
          const Text(
            'Оплата прошла!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            successMessage,
            style: TextStyle(fontSize: 16, color: AppColors.grey2),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              child: const Text('Готово'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedCard(String? error) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.cancelColor,
            size: 64,
          ),
          const SizedBox(height: 24),
          const Text(
            'Оплата не удалась',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            error ?? 'Неизвестная ошибка',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.grey2),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Вернуться'),
            ),
          ),
        ],
      ),
    );
  }
}
