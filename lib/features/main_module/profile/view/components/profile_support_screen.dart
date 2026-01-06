import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileSupportScreen extends StatelessWidget {
  const ProfileSupportScreen({super.key});

  static const _accent = Color(0xFFFF8A00);
  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);
  Future<void> _launchUri(BuildContext context, Uri uri) async {
    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть приложение.')),
      );
    }
  }

  Future<void> _callSupport(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    await _launchUri(context, uri);
  }

  Future<void> _openWhatsApp(BuildContext context, String phoneE164Digits) async {
    final uri = Uri.parse('https://wa.me/$phoneE164Digits');
    await _launchUri(context, uri);
  }

  Future<void> _openTelegram(BuildContext context, String phoneE164Digits) async {
    final tgUri = Uri.parse('tg://resolve?phone=$phoneE164Digits');
    if (await canLaunchUrl(tgUri)) {
      await _launchUri(context, tgUri);
      return;
    }

    final webUri = Uri.parse('https://t.me/+${phoneE164Digits}');
    await _launchUri(context, webUri);
  }

  @override
  Widget build(BuildContext context) {
    const phoneDisplay = '+996 509 10 67 88';
    const phoneDigits = '996509106788'; // E.164 digits

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Служба поддержки',
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: _tileBorder,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Если что-то пошло не так — напишите нам или позвоните. '
                          'Мы поможем с заказами, оплатой и приложением.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: _greyText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _tileBorder, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x11000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Color(0x08000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Телефон поддержки',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                              color: _greyText,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            phoneDisplay,
                            style: const TextStyle(
                              fontSize: 20,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Ежедневно с 09:00 до 21:00 по Бишкеку.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                              color: _greyText,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                _callSupport(context, phoneDisplay);
                              },
                              child: const Text(
                                'Позвонить в поддержку',
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Мессенджеры',
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SupportButton(
                      label: 'Написать в WhatsApp',
                      icon: Icons.chat_bubble_rounded,
                      onTap: () => _openWhatsApp(context, phoneDigits),
                    ),
                    const SizedBox(height: 8),
                    _SupportButton(
                      label: 'Чат в Telegram',
                      icon: Icons.telegram,
                      onTap: () => _openTelegram(context, phoneDigits),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Частые вопросы',
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _FaqTile(
                      question: 'Заказ не подтверждается, что делать?',
                      answer:
                      'Проверьте интернет, попробуйте перезапустить приложение. '
                          'Если не помогает — напишите нам в поддержку.',
                    ),
                    const SizedBox(height: 6),
                    const _FaqTile(
                      question: 'Списали деньги, но заказ не создался.',
                      answer:
                      'Сделайте скриншот операции и отправьте в поддержку — мы разберёмся.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSoonSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
        Text('Интеграция с телефоном и мессенджерами будет добавлена позже.'),
      ),
    );
  }
}

class _SupportButton extends StatelessWidget {
  const _SupportButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  static const _accent = Color(0xFFFF8A00);
  static const _tileBorder = Color(0xFFE9EDF2);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: _accent),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _tileBorder, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _tileBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 15,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: _greyText,
            ),
          ),
        ],
      ),
    );
  }
}
