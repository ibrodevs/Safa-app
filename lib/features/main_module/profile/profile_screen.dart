// lib/features/main_module/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _accent = Color(0xFFFF8A00);
  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _chev = Color(0xFFC7CFD9);
  static const _linkBlue = Color(0xFF4A90E2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
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
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?w=256',
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _HeaderInfo(
                      name: 'Арслан Абдыкаров',
                      phone: '+996 997 91-91-70',
                      city: 'Bishkek',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, thickness: 1, color: _tileBorder),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _tileBorder, width: 1),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x11000000), blurRadius: 20, offset: Offset(0, 8)),
                    BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: const [
                    _ProfileTile(
                      iconAsset: 'assets/icons/ic_notification.svg',
                      title: 'Уведомление',
                    ),
                    SizedBox(height: 2),
                    _ProfileTile(
                      iconAsset: 'assets/icons/ic_human.svg',
                      title: 'Аккаунт',
                    ),
                    SizedBox(height: 2),
                    _ProfileTile(
                      iconAsset: 'assets/icons/ic_clock.svg',
                      title: 'История пополнений/трат',
                    ),
                    SizedBox(height: 2),
                    _ProfileTile(
                      iconAsset: 'assets/icons/ic_phone.svg',
                      title: 'Служба поддержки',
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
  const _HeaderInfo({required this.name, required this.phone, required this.city});
  final String name;
  final String phone;
  final String city;

  static const _greyText = Color(0xFF9FA4AD);
  static const _linkBlue = Color(0xFF4A90E2);

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
            fontWeight: FontWeight.w700,
            color: _greyText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          city,
          style: const TextStyle(
            fontSize: 17,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: _greyText,
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.iconAsset, required this.title, this.onTap});
  final String iconAsset;
  final String title;
  final VoidCallback? onTap;

  static const _accent = Color(0xFFFF8A00);
  static const _chev = Color(0xFFC7CFD9);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 8, 18),
        child: Row(
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(_accent, BlendMode.srcIn),
              placeholderBuilder: (_) => const Icon(Icons.circle, size: 22, color: _accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 24, color: _chev),
          ],
        ),
      ),
    );
  }
}

class _ProfileDivider extends StatelessWidget {
  const _ProfileDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, indent: 52, color: Color(0xFFE9EDF2));
  }
}
