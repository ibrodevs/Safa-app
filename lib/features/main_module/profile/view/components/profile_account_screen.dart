import 'package:flutter/material.dart';

class ProfileAccountScreen extends StatelessWidget {
  const ProfileAccountScreen({super.key});

  static const _accent = Color(0xFFFF8A00);
  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);

  @override
  Widget build(BuildContext context) {
    // Здесь пока заглушки — потом можно будет прокинуть реальные данные профиля.
    const name = 'Ваше имя';
    const phone = '+996 XXX XX XX XX';
    const city = 'Ваш город';

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
                    'Аккаунт',
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
                      'Личные данные',
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Используются для регистрации и оформления заказов.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                        color: _greyText,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
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
                        children: [
                          _AccountTile(
                            label: 'Имя и фамилия',
                            value: name,
                            onTap: () => _showSoonSnack(context),
                          ),
                          const _AccountDivider(),
                          _AccountTile(
                            label: 'Город',
                            value: city,
                            onTap: () => _showSoonSnack(context),
                          ),
                          const _AccountDivider(),
                          _AccountTile(
                            label: 'Номер телефона',
                            value: phone,
                            onTap: () => _showSoonSnack(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Безопасность',
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
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
                        children: [
                          _AccountTile(
                            label: 'Сменить пароль',
                            value: 'Рекомендуется',
                            valueStyle: const TextStyle(
                              fontSize: 13,
                              color: _greyText,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                            onTap: () => _showSoonSnack(context),
                          ),
                          const _AccountDivider(),
                          _AccountTile(
                            label: 'Выйти из аккаунта',
                            value: '',
                            valueStyle: const TextStyle(
                              fontSize: 13,
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            onTap: () => _showSoonSnack(context),
                            showChevron: false,
                          ),
                        ],
                      ),
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
        content: Text('Функционал редактирования будет добавлен позже.'),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.label,
    required this.value,
    this.valueStyle,
    this.onTap,
    this.showChevron = true,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;
  final VoidCallback? onTap;
  final bool showChevron;

  static const _greyText = Color(0xFF9FA4AD);
  static const _chev = Color(0xFFC7CFD9);

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (hasValue) ...[
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: valueStyle ??
                          const TextStyle(
                            fontSize: 15,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                            color: _greyText,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: _chev,
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountDivider extends StatelessWidget {
  const _AccountDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFE9EDF2),
    );
  }
}
