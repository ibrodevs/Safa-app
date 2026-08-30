import 'dart:io';

import 'package:dogo/core/utils/app_colors.dart';
import 'package:dogo/core/utils/friendly_error.dart';
import 'package:dogo/data/network/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repo/carrier_profile_repository.dart';
import '../provider/carrier_profile_provider.dart';

const _accent = AppColors.primary;
const _greyText = Color(0xFF9FA4AD);
const _tileBorder = Color(0xFFE9EDF2);
const _chev = Color(0xFFC7CFD9);
const _green = Color(0xFF22C55E);

class CarrierProfileScreen extends StatelessWidget {
  const CarrierProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          CarrierProfileProvider(CarrierProfileRepository(ApiService.instance))
            ..load(),
      child: const _CarrierProfileBody(),
    );
  }
}

class _CarrierProfileBody extends StatefulWidget {
  const _CarrierProfileBody();

  @override
  State<_CarrierProfileBody> createState() => _CarrierProfileBodyState();
}

class _CarrierProfileBodyState extends State<_CarrierProfileBody> {
  static const _avatarPreferenceKey = 'carrier_local_avatar_path_v1';
  String? _localAvatarPath;
  bool _pickingAvatar = false;

  /// Идёт отправка выбранного фото на сервер.
  bool _uploadingAvatar = false;

  /// Доля отправленных байт (0..1) для кольца прогресса.
  double _avatarUploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _loadLocalAvatar();
  }

  Future<void> _loadLocalAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_avatarPreferenceKey);
    if (path == null || path.isEmpty) return;
    if (!await File(path).exists()) {
      await prefs.remove(_avatarPreferenceKey);
      return;
    }
    if (mounted) setState(() => _localAvatarPath = path);
  }

  Future<void> _pickAvatar() async {
    if (_pickingAvatar || _uploadingAvatar) return;
    _pickingAvatar = true;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 88,
      );
      if (picked == null) return;
      if (!mounted) return;

      // Показываем загрузку сразу после выбора, включая подготовку и
      // копирование файла, а не только после начала сетевого PATCH.
      setState(() {
        _uploadingAvatar = true;
        _avatarUploadProgress = 0;
      });

      final directory = await getApplicationDocumentsDirectory();
      final suffix = picked.name.contains('.')
          ? '.${picked.name.split('.').last.toLowerCase()}'
          : '.jpg';
      final saved = await File(
        picked.path,
      ).copy('${directory.path}/safa_carrier_avatar$suffix');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_avatarPreferenceKey, saved.path);
      if (!mounted) return;

      // Локальную копию показываем сразу — превью не должно ждать сеть.
      setState(() {
        _localAvatarPath = saved.path;
      });

      await _uploadAvatar(saved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось выбрать фотографию')),
      );
    } finally {
      _pickingAvatar = false;
    }
  }

  /// Отправляет фото на backend и обновляет профиль.
  ///
  /// Раньше аватар сохранялся только на устройстве: на сервере фото не
  /// появлялось, а специалист не видел ни прогресса, ни результата.
  Future<void> _uploadAvatar(File file) async {
    try {
      await ApiService.instance.uploadAvatar(
        file: file,
        onProgress: (value) {
          if (!mounted) return;
          setState(() => _avatarUploadProgress = value);
        },
      );
      if (!mounted) return;

      setState(() {
        _uploadingAvatar = false;
        _avatarUploadProgress = 1;
      });
      await context.read<CarrierProfileProvider>().load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Фотография профиля обновлена')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyErrorMessage(
              e,
              fallback: 'Не удалось загрузить фотографию',
            ),
          ),
        ),
      );
    }
  }

  Widget _buildAvatar(String? remoteAvatar) {
    final localPath = _localAvatarPath;
    Widget image;
    if (localPath != null && localPath.isNotEmpty) {
      image = Image.file(
        File(localPath),
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _AvatarPlaceholder(),
      );
    } else if (remoteAvatar != null && remoteAvatar.isNotEmpty) {
      image = Image.network(
        remoteAvatar,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _AvatarPlaceholder(),
      );
    } else {
      image = const _AvatarPlaceholder();
    }

    return Semantics(
      button: true,
      label: _uploadingAvatar
          ? 'Фотография профиля загружается'
          : 'Выбрать фотографию профиля',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _pickAvatar,
        child: SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: image,
                ),
              ),
              if (_uploadingAvatar)
                Positioned(
                  left: 0,
                  top: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.black.withValues(alpha: 0.45),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.6,
                              color: Colors.white,
                              // До первого onSendProgress крутим бесконечный
                              // индикатор, дальше показываем реальную долю.
                              value: _avatarUploadProgress > 0
                                  ? _avatarUploadProgress
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _avatarUploadProgress > 0
                                ? '${(_avatarUploadProgress * 100).round()}%'
                                : 'Загрузка',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _uploadingAvatar ? _greyText : _accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    _uploadingAvatar
                        ? Icons.cloud_upload_rounded
                        : Icons.photo_camera_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatKgPhone(String? input) {
    if (input == null) return '—';

    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '—';

    if (digits.startsWith('0') && digits.length == 10) {
      digits = digits.substring(1);
    }

    if (digits.length == 9) {
      digits = '996$digits';
    }

    if (digits.length == 12 && digits.startsWith('996')) {
      final op = digits.substring(3, 6); // 997
      final a = digits.substring(6, 8); // 91
      final b = digits.substring(8, 10); // 91
      final c = digits.substring(10, 12); // 70
      return '+996 $op $a-$b-$c';
    }

    return input.trim().startsWith('+') ? input.trim() : '+$digits';
  }

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
        body: Center(child: Text(provider.error!, textAlign: TextAlign.center)),
      );
    }

    final name = profile?.firstName ?? '';
    final city = profile?.city ?? '';
    final avatar = profile?.avatar;
    final rate = profile?.rate ?? 0;
    final clientRateCount = profile?.clientRateCount ?? 0;
    final phone = formatKgPhone(profile?.phoneNumber);

    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          backgroundColor: Colors.white,
          color: _accent,
          onRefresh: () => context.read<CarrierProfileProvider>().load(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(14, 24, 14, 24 + bottom),
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
                    _buildAvatar(avatar),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _HeaderInfo(
                        name: name.isEmpty ? '—' : name,
                        phone: phone,
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
                    border: Border.all(color: Color(0xFFF4F4F4), width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F808080),
                        blurRadius: 60,
                        offset: Offset(0, 3),
                      ),
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 12,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ProfileTile(
                        iconAsset: 'assets/icons/ic_notification.svg',
                        title: 'Уведомление',
                        onTap: () =>
                            context.push('/profile/notifications?role=carrier'),
                      ),
                      const _ProfileInnerDivider(),
                      _ProfileTile(
                        iconAsset: 'assets/icons/ic_human.svg',
                        title: 'Аккаунт',
                        onTap: () => context.push('/profile/account'),
                      ),
                      const _ProfileInnerDivider(),
                      _ProfileTile(
                        iconAsset: 'assets/icons/ic_wallet.svg',
                        title: 'Баланс и начисления',
                        onTap: () => context.push('/profile/balance-history'),
                      ),
                      const _ProfileInnerDivider(),
                      _ProfileTile(
                        iconAsset: 'assets/icons/ic_phone.svg',
                        title: 'Служба поддержки',
                        onTap: () => context.push('/profile/support'),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
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
                      Row(
                        children: [
                          SvgPicture.asset('assets/icons/ic_rait.svg'),
                          const SizedBox(width: 6),
                          const Text(
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
                      const SizedBox(width: 26),
                      Container(
                        width: 1.5,
                        height: 30,
                        color: Color(0xFF424242),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'От $clientRateCount клиентов',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF54546c),
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

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      color: const Color(0xFFE5E7EB),
      child: const Icon(Icons.person, size: 40, color: Colors.white),
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
            const Icon(Icons.chevron_right_rounded, size: 24, color: _chev),
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
  const _StatisticsCard({required this.createdAt});

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

          _StatLine(
            leftText: grossTotal.toString(),
            rightTopText: deltaText,
            rightTopStyle: TextStyle(
              fontSize: 16,
              height: 1.1,
              fontWeight: FontWeight.w700,
              color: deltaColor,
            ),
            rightBottomText: 'Заработано\nза сегодня',
            rightBottomStyle: const TextStyle(
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: Color(0x9E1E1E3E),
            ),
            valueStyle: const TextStyle(
              fontSize: 40,
              height: 1.0,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 18),
          _StatLine(
            leftText: commission.toString(),
            rightTopText: null,
            rightBottomText: 'Комиссия',
            rightBottomStyle: const TextStyle(
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: Color(0x9E1E1E3E),
            ),
            valueStyle: const TextStyle(
              fontSize: 32,
              height: 1.0,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 18),
          _StatLine(
            leftText: clients.toString(),
            rightTopText: null,
            rightBottomText: 'Клиентов',
            rightBottomStyle: const TextStyle(
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: Color(0x9E1E1E3E),
            ),
            valueStyle: const TextStyle(
              fontSize: 32,
              height: 1.0,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.leftText,
    required this.valueStyle,
    required this.rightBottomText,
    required this.rightBottomStyle,
    this.rightTopText,
    this.rightTopStyle,
  });

  final String leftText;
  final TextStyle valueStyle;
  final String? rightTopText;
  final TextStyle? rightTopStyle;
  final String rightBottomText;
  final TextStyle rightBottomStyle;

  static const double leftWidth = 90;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: leftWidth,
            child: Align(
              alignment: Alignment
                  .centerLeft, // или centerRight если хочешь прижать числа к линии
              child: Text(leftText, style: valueStyle, maxLines: 1),
            ),
          ),
          const SizedBox(width: 18),
          Container(width: 1, color: Colors.black),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rightTopText != null) ...[
                  Text(rightTopText!, style: rightTopStyle),
                  const SizedBox(height: 4),
                ],
                Text(rightBottomText, style: rightBottomStyle),
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
    final textColorTop = Colors.black;
    final textColorBottom = AppColors.black;

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
