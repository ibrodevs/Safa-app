// lib/features/main_module/profile/carrier_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CarrierProfileScreen extends StatelessWidget {
  const CarrierProfileScreen({super.key});

  static const _accent = Color(0xFFFF8A00);
  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _chev = Color(0xFFC7CFD9);
  static const _green = Color(0xFF22C55E);
  static const _ratingGrey = Color(0xFF737A86);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Профиль',
                style: TextStyle(
                  fontSize: 20,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?w=256',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: _HeaderInfo(
                      name: 'Начальник',
                      phone: '+996 997 91-91-70',
                      city: 'Bishkek',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, thickness: 1, color: _tileBorder),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _tileBorder, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: const [
                    _ProfileTile(
                      iconAsset: 'assets/icons/ic_notification.svg',
                      title: 'Уведомление',
                    ),
                    _ProfileInnerDivider(),
                    _ProfileTile(
                      iconAsset: 'assets/icons/ic_human.svg',
                      title: 'Аккаунт',
                    ),
                    _ProfileInnerDivider(),
                    _ProfileTile(
                      iconAsset: 'assets/icons/ic_wallet.svg',
                      title: 'Пополнить счет',
                    ),
                    _ProfileInnerDivider(),
                    _ProfileTile(
                      iconAsset: 'assets/icons/ic_clock.svg',
                      title: 'История пополнений/трат',
                    ),
                    _ProfileInnerDivider(),
                    _ProfileTile(
                      iconAsset: 'assets/icons/ic_phone.svg',
                      title: 'Служба поддержки',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _tileBorder, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Row(
                  children: [
                    const Text(
                      '92',
                      style: TextStyle(
                        fontSize: 40,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Row(
                      children: const [
                        Icon(
                          Icons.emoji_events_rounded,
                          size: 22,
                          color: _green,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Рейтинг',
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 1,
                      height: 30,
                      color: _tileBorder,
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'От 432 клиентов',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        color: _ratingGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _tileBorder, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Статистика',
                      style: TextStyle(
                        fontSize: 28,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 68,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: const [
                          _StatChip(
                            titleTop: '24 сентября',
                            titleBottom: 'Сегодня',
                            selected: true,
                          ),
                          SizedBox(width: 12),
                          _StatChip(
                            titleTop: '23 сентября',
                            titleBottom: 'Вчера',
                            selected: false,
                          ),
                          SizedBox(width: 12),
                          _StatChip(
                            titleTop: '22 сентября',
                            titleBottom: '',
                            selected: false,
                          ),
                          SizedBox(width: 12),
                          _StatChip(
                            titleTop: '21 сентября',
                            titleBottom: '',
                            selected: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({
    required this.name,
    required this.phone,
    required this.city,
  });

  final String name;
  final String phone;
  final String city;

  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            height: 1.1,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          phone,
          style: const TextStyle(
            fontSize: 17,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: _greyText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          city,
          style: const TextStyle(
            fontSize: 17,
            height: 1.1,
            fontWeight: FontWeight.w600,
            color: _greyText,
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.iconAsset,
    required this.title,
    this.onTap,
  });

  final String iconAsset;
  final String title;
  final VoidCallback? onTap;

  static const _accent = Color(0xFFFF8A00);
  static const _chev = Color(0xFFC7CFD9);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 8, 18),
        child: Row(
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(_accent, BlendMode.srcIn),
              placeholderBuilder: (_) =>
              const Icon(Icons.circle, size: 24, color: _accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 24,
              color: _chev,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInnerDivider extends StatelessWidget {
  const _ProfileInnerDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 58,
      color: Color(0xFFEFEFF4),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.titleTop,
    required this.titleBottom,
    required this.selected,
  });

  final String titleTop;
  final String titleBottom;
  final bool selected;

  static const _accent = Color(0xFFFF8A00);

  @override
  Widget build(BuildContext context) {
    final bg = selected ? _accent : Colors.white;
    final borderColor = _accent;
    final textColorTop = selected ? Colors.white : Colors.black;
    final textColorBottom = selected ? Colors.white : _accent;

    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: selected ? 0 : 1.4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleTop,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: textColorTop,
            ),
          ),
          if (titleBottom.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              titleBottom,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 1.1,
                fontWeight: FontWeight.w600,
                color: textColorBottom,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
