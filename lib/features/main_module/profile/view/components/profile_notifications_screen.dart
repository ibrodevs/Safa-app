import 'package:flutter/material.dart';

class ProfileNotificationsScreen extends StatefulWidget {
  const ProfileNotificationsScreen({super.key});

  @override
  State<ProfileNotificationsScreen> createState() =>
      _ProfileNotificationsScreenState();
}

class _ProfileNotificationsScreenState
    extends State<ProfileNotificationsScreen> {
  static const _accent = Color(0xFFFF8A00);
  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);

  bool _newShipments = true;
  bool _statusUpdates = true;
  bool _promo = false;
  bool _system = true;

  @override
  Widget build(BuildContext context) {
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
                    'Уведомления',
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
                child: Container(
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
                      _SwitchTile(
                        title: 'Новые заказы рядом',
                        subtitle: 'Когда появляется новый груз поблизости.',
                        value: _newShipments,
                        onChanged: (v) => setState(() => _newShipments = v),
                      ),
                      const _SettingsDivider(),
                      _SwitchTile(
                        title: 'Изменение статуса',
                        subtitle: 'Принятие, выполнение и отмена заказов.',
                        value: _statusUpdates,
                        onChanged: (v) => setState(() => _statusUpdates = v),
                      ),
                      const _SettingsDivider(),
                      _SwitchTile(
                        title: 'Акции и промокоды',
                        subtitle: 'Редкие, но приятные уведомления о бонусах.',
                        value: _promo,
                        onChanged: (v) => setState(() => _promo = v),
                      ),
                      const _SettingsDivider(),
                      _SwitchTile(
                        title: 'Системные уведомления',
                        subtitle: 'Важно для стабильной работы приложения.',
                        value: _system,
                        onChanged: (v) => setState(() => _system = v),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16), // небольшой hint
              child: Text(
                'Позже сюда можно будет привязать реальные типы пушей '
                    'с бэкенда, сейчас это локальные переключатели.',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                  color: _greyText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  static const _greyText = Color(0xFF9FA4AD);
  static const _accent = Color(0xFFFF8A00);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    color: _greyText,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: _accent,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE9EDF2),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFE9EDF2),
    );
  }
}
