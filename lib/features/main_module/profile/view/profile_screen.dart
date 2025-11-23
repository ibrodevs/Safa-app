// lib/features/main_module/profile/view/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../provider/profile_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _accent = Color(0xFFFF8A00);
  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider()..loadProfile(),
      child: const _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileProvider>();
    final profile = state.profile;

    final name = profile != null && profile.fullName.isNotEmpty
        ? profile.fullName
        : (state.loading ? 'Загрузка...' : '—');

    final rawPhone = profile?.user.phoneNumber ?? '';
    final phone = rawPhone.isEmpty
        ? '—'
        : (rawPhone.startsWith('+') ? rawPhone : '+$rawPhone');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          backgroundColor: Colors.white,
          color: const Color(0xFFFF8A00),
          onRefresh: () => context.read<ProfileProvider>().loadProfile(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
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
                    _Avatar(avatarUrl: profile?.avatar),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeaderInfo(
                        name: name,
                        phone: phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE9EDF2),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFE9EDF2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
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
                const SizedBox(height: 200),

                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.error!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.avatarUrl});

  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          url,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.asset(
        'assets/images/img_placeholder.png',
        width: 76,
        height: 76,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({
    required this.name,
    required this.phone,
    this.city,
  });

  final String name;
  final String phone;
  final String? city;

  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    final hasCity = city != null && city!.trim().isNotEmpty;

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
        if (hasCity) ...[
          const SizedBox(height: 4),
          Text(
            city!,
            style: const TextStyle(
              fontSize: 17,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: _greyText,
            ),
          ),
        ],
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
              placeholderBuilder: (_) =>
              const Icon(Icons.circle, size: 22, color: _accent),
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

