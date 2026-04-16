import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/styles.dart';
import '../../../../core/widgets/primary_button.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _accepted = false;
  final ScrollController _scrollController = ScrollController();

  Future<void> _onAccept() async {
    if (!_accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, примите политику конфиденциальности'),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_accepted', true);

    if (!mounted) return;

    final userRole = prefs.getString('user_role');
    if (userRole == 'carrier') {
      context.go('/home-carrier');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Политика конфиденциальности',
                      style: AppTextStyles.titleBlackStyle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ваша конфиденциальность важна для нас',
                      style: AppTextStyles.subtitleStyle.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      '1. Какие данные мы собираем',
                      'Мы собираем данные, необходимые для работы сервиса доставки: ваше имя, номер телефона, данные о местоположении для отслеживания посылок в реальном времени, а также информацию о ваших заказах.',
                    ),
                    _buildSection(
                      '2. Как мы используем данные',
                      'Ваше местоположение используется для построения маршрута курьером и информирования клиента о статусе доставки. Номер телефона необходим для связи и подтверждения заказов.',
                    ),
                    _buildSection(
                      '3. Передача данных третьим лицам',
                      'Мы не продаем ваши данные. Данные передаются только участникам процесса доставки (курьеру или клиенту) исключительно для выполнения услуги.',
                    ),
                    _buildSection(
                      '4. Безопасность',
                      'Мы используем современные методы шифрования для защиты вашей личной информации и данных о платежах.',
                    ),
                    _buildSection(
                      '5. Ваши права',
                      'Вы имеете право запросить удаление вашего аккаунта и всех связанных данных в любой момент через службу поддержки.',
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Нажимая "Принять", вы соглашаетесь с условиями использования и политикой конфиденциальности SafaApp.',
                      style: AppTextStyles.subtitleStyle.copyWith(
                        color: AppColors.grey2,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _accepted = !_accepted),
                    child: Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _accepted,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (val) {
                              setState(() => _accepted = val ?? false);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Я принимаю политику конфиденциальности',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: PrimaryButton(
                      text: 'Принять и продолжить',
                      onPressed: _accepted ? _onAccept : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
