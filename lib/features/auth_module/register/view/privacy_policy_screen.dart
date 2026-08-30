import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/design/app_design.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../data/network/api_service.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _accepted = false;
  bool _showHint = false;
  String? _dynamicContent;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchPolicy();
  }

  Future<void> _fetchPolicy() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyAccepted = prefs.getBool('privacy_accepted') ?? false;
      if (alreadyAccepted && mounted) {
        setState(() => _accepted = true);
      }

      final text = await ApiService.instance.getPrivacyPolicy();
      if (mounted && text.isNotEmpty) {
        setState(() => _dynamicContent = text);
      }
    } catch (_) {
      // Использовать стандартный встроенный текст при отсутствии соединения
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onAccept() async {
    if (!_accepted) {
      setState(() => _showHint = true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_accepted', true);

    if (!mounted) return;

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
      return;
    }

    final userRole = prefs.getString('user_role');
    context.go(userRole == 'carrier' ? '/home-carrier' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return AppScreenScaffold(
      backgroundColor: AppColors.surface,
      showBackButton: canPop,
      title: 'Политика конфиденциальности',
      subtitle: 'Ваша конфиденциальность важна для нас',
      footer: Column(
        children: [
          if (_showHint && !_accepted) ...[
            const AppFormError(
              message: 'Чтобы продолжить, примите политику конфиденциальности',
            ),
            AppSpacing.gapSm,
          ],
          if (!_accepted || !canPop) ...[
            _AcceptCheckbox(
              value: _accepted,
              onChanged: (value) => setState(() {
                _accepted = value;
                if (value) _showHint = false;
              }),
            ),
            AppSpacing.gapSm,
          ],
          AppPrimaryButton(
            label: canPop && _accepted ? 'Понятно' : 'Принять и продолжить',
            onPressed: _onAccept,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loading && _dynamicContent == null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          ] else if (_dynamicContent != null && _dynamicContent!.trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: AppRadius.allSm,
              ),
              child: Text(
                _dynamicContent!,
                style: AppTypography.body.copyWith(
                  height: 1.55,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ] else ...[
            const _Section(
              title: '1. Какие данные мы собираем',
              body:
                  'Мы собираем данные, необходимые для работы сервиса '
                  'доставки: ваше имя, номер телефона, данные о местоположении '
                  'для отслеживания посылок в реальном времени, а также '
                  'информацию о ваших заказах.',
            ),
            const _Section(
              title: '2. Как мы используем данные',
              body:
                  'Ваше местоположение используется для построения маршрута '
                  'курьером и информирования клиента о статусе доставки. '
                  'Номер телефона необходим для связи и подтверждения заказов.',
            ),
            const _Section(
              title: '3. Передача данных третьим лицам',
              body:
                  'Мы не продаём ваши данные. Данные передаются только '
                  'участникам процесса доставки (курьеру или клиенту) '
                  'исключительно для выполнения услуги.',
            ),
            const _Section(
              title: '4. Безопасность',
              body:
                  'Мы используем современные методы шифрования для защиты '
                  'вашей личной информации и данных о платежах.',
            ),
            const _Section(
              title: '5. Ваши права',
              body:
                  'Вы имеете право запросить удаление вашего аккаунта и всех '
                  'связанных данных в любой момент через службу поддержки.',
            ),
          ],
          AppSpacing.gapXs,
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: AppRadius.allSm,
            ),
            child: Text(
              'Нажимая «Принять и продолжить», вы соглашаетесь с условиями '
              'использования и политикой конфиденциальности Safa App.',
              style: AppTypography.caption,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.cardTitle),
          AppSpacing.gapXxs,
          Text(body, style: AppTypography.bodySecondary),
        ],
      ),
    );
  }
}

class _AcceptCheckbox extends StatelessWidget {
  const _AcceptCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: 'Я принимаю политику конфиденциальности',
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: AppRadius.allSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: value,
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  onChanged: (v) => onChanged(v ?? false),
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: Text(
                  'Я принимаю политику конфиденциальности',
                  style: AppTypography.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
