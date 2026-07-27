import 'package:dogo/core/utils/snackbar_utils.dart';
import 'package:dogo/features/main_module/profile/provider/support_provider.dart';
import 'package:flutter/material.dart';

import 'package:dogo/core/design/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileSupportScreen extends StatefulWidget {
  const ProfileSupportScreen({super.key});

  @override
  State<ProfileSupportScreen> createState() => _ProfileSupportScreenState();
}

class _ProfileSupportScreenState extends State<ProfileSupportScreen> {
  static const _accent = AppColors.primary;
  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportProvider>().fetchSupport();
    });
  }

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppSnackBar.showError(context, message: 'Не удалось открыть приложение.');
    }
  }

  Future<void> _callSupport(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s+'), ''));
    await _launchUri(context, uri);
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    await _launchUri(context, uri);
  }

  Future<void> _openTelegram(BuildContext context, String telegram) async {
    // Сначала пробуем нативное приложение Telegram, затем веб-ссылку.
    final Uri appUri;
    final Uri webUri;

    if (telegram.startsWith('@')) {
      final domain = telegram.substring(1);
      appUri = Uri.parse('tg://resolve?domain=$domain');
      webUri = Uri.parse('https://t.me/$domain');
    } else {
      final digits = telegram.replaceAll(RegExp(r'[^\d]'), '');
      appUri = Uri.parse('tg://resolve?phone=$digits');
      webUri = Uri.parse('https://t.me/+$digits');
    }

    final canOpenApp = await canLaunchUrl(appUri);
    if (!context.mounted) return;

    await _launchUri(context, canOpenApp ? appUri : webUri);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupportProvider>();
    final support = provider.support;

    final phoneDisplay = support?.phone ?? '+996 509 10 67 88';
    final workingHours =
        support?.workingHours ?? 'Ежедневно с 09:00 до 21:00 по Бишкеку.';
    final telegram = support?.telegram ?? '996509106788';
    final message =
        support?.message ??
        'Если что-то пошло не так — напишите нам или позвоните. Мы поможем с заказами, оплатой и приложением.';

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
                  if (provider.loading)
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _accent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: _tileBorder),
            Expanded(
              child: RefreshIndicator(
                onRefresh: provider.fetchSupport,
                color: _accent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: const TextStyle(
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
                            Text(
                              workingHours,
                              style: const TextStyle(
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
                        onTap: () => _openWhatsApp(context, phoneDisplay),
                      ),
                      const SizedBox(height: 8),
                      _SupportButton(
                        label: 'Чат в Telegram',
                        icon: Icons.telegram,
                        onTap: () => _openTelegram(context, telegram),
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
            ),
          ],
        ),
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

  static const _accent = AppColors.primary;
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
  const _FaqTile({required this.question, required this.answer});

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
