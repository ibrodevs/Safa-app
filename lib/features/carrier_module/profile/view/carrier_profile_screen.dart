
import 'package:dogo/data/network/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../data/repo/carrier_profile_repository.dart';
import '../provider/carrier_profile_provider.dart';

const _accent = Color(0xFFFF8A00);
const _greyText = Color(0xFF9FA4AD);
const _tileBorder = Color(0xFFE9EDF2);
const _chev = Color(0xFFC7CFD9);
const _green = Color(0xFF22C55E);
const _ratingGrey = Color(0xFF737A86);


class CarrierProfileScreen extends StatelessWidget {
  const CarrierProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CarrierProfileProvider(
        CarrierProfileRepository(ApiService.instance),
      )..load(),
      child: const _CarrierProfileBody(),
    );
  }
}

class _CarrierProfileBody extends StatelessWidget {
  const _CarrierProfileBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CarrierProfileProvider>();
    final profile = provider.profile;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    if (provider.loading && profile == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null && profile == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            provider.error!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final name = profile?.firstName ?? '';
    final city = profile?.city ?? '';
    final avatar = profile?.avatar;
    final rate = profile?.rate ?? 0;
    final clientRateCount = profile?.clientRateCount ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          backgroundColor: Colors.white,
          color: _accent,
          onRefresh: () => context.read<CarrierProfileProvider>().load(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
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
                      child: avatar != null && avatar.isNotEmpty
                          ? Image.network(
                        avatar,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        width: 80,
                        height: 80,
                        color: const Color(0xFFE5E7EB),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _HeaderInfo(
                        name: name.isEmpty ? '—' : name,
                        phone: '+${profile?.phoneNumber ?? '—'}',
                        city: city.isEmpty ? '—' : city,
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
                  child: const Column(
                    children: [
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      Text(
                        rate.toString(),
                        style: const TextStyle(
                          fontSize: 40,
                          height: 1.0,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Row(
                        children: [
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
                      Text(
                        'От $clientRateCount клиентов',
                        style: const TextStyle(
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

                if (profile != null)
                  _StatisticsCard(createdAt: profile.createdAt),
              ],
            ),
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

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard({
    required this.createdAt,
  });

  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CarrierProfileProvider>();
    final days = provider.days;
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedDate = provider.selectedDate ?? days.first;
    final today = DateTime.now();
    final selectedStats = provider.selectedStats;
    final grossTotal = selectedStats?.grossTotal ?? 0;
    final commission = selectedStats?.commission ?? 0;
    final clients = selectedStats?.clients ?? 0;
    final change = provider.selectedChangePercent;

    String deltaText = '0%';
    Color deltaColor = _greyText;
    if (change != null) {
      final sign = change > 0 ? '+' : '';
      deltaText = '$sign$change%';
      if (change > 0) {
        deltaColor = _green;
      } else if (change < 0) {
        deltaColor = const Color(0xFFEF4444);
      }
    }

    return Container(
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
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final date = days[index];
                final selected = _sameDate(date, selectedDate);
                final titleTop = _formatRuDate(date);
                final bottomLabel = _bottomLabel(date, today);
                return _StatChip(
                  titleTop: titleTop,
                  titleBottom: bottomLabel,
                  selected: selected,
                  onTap: () =>
                      context.read<CarrierProfileProvider>().selectDate(date),
                );
              },
            ),
          ),
          if (provider.statsLoading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 18),

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grossTotal.toString(),
                      style: const TextStyle(
                        fontSize: 40,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      commission.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      clients.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        height: 1.0,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Container(
                  width: 1,
                  color: _tileBorder,
                ),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deltaText,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: deltaColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Заработано\nза сегодня',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: _greyText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    const Text(
                      'Комиссия',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: _greyText,
                      ),
                    ),
                    const SizedBox(height: 22),

                    const Text(
                      'Клиентов',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: _greyText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.titleTop,
    required this.titleBottom,
    required this.selected,
    required this.onTap,
  });

  final String titleTop;
  final String titleBottom;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? _accent : Colors.white;
    final borderColor = _accent;
    final textColorTop = selected ? Colors.white : Colors.black;
    final textColorBottom = selected ? Colors.white : _accent;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: selected ? 0 : 1.4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
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
      ),
    );
  }
}


String _formatRuDate(DateTime d) {
  const months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  final m = months[d.month - 1];
  return '${d.day} $m';
}

String _bottomLabel(DateTime date, DateTime today) {
  final todayDate = DateTime(today.year, today.month, today.day);
  final d = DateTime(date.year, date.month, date.day);
  if (_sameDate(d, todayDate)) return 'Сегодня';
  if (_sameDate(d, todayDate.subtract(const Duration(days: 1)))) {
    return 'Вчера';
  }
  return '';
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
