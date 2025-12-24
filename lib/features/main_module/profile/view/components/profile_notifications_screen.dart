import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dogo/data/network/api_service.dart';

import '../../data/model/app_notification_model.dart';
import '../../data/repo/notifications_repo.dart';
import '../../provider/notifications_provider.dart';


class ProfileNotificationsScreen extends StatefulWidget {
  const ProfileNotificationsScreen({super.key});

  @override
  State<ProfileNotificationsScreen> createState() => _ProfileNotificationsScreenState();
}

class _ProfileNotificationsScreenState extends State<ProfileNotificationsScreen> {
  static const _accent = Color(0xFFFF8A00);
  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);

  bool _newShipments = true;
  bool _statusUpdates = true;
  bool _promo = false;
  bool _system = true;

  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final p = context.read<NotificationsProvider>();
    if (p.loading || p.loadingMore || !p.hasMore) return;

    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 420) {
      p.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final repo = NotificationsRepository(ApiService.instance);
        final p = NotificationsProvider(repo);
        p.loadInitial();
        return p;
      },
      child: Builder(
        builder: (context) {
          final p = context.watch<NotificationsProvider>();

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
                        const Spacer(),
                        _UnreadPill(count: p.unreadCount),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: _tileBorder),
                  Expanded(
                    child: RefreshIndicator(
                      color: _accent,
                      onRefresh: p.refresh,
                      child: SingleChildScrollView(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: Column(
                          children: [
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
                                  const _SettingsDivider(),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                                    child: Row(
                                      children: [
                                        const Text(
                                          'История',
                                          style: TextStyle(
                                            fontSize: 16,
                                            height: 1.1,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const Spacer(),
                                        _FilterPill(
                                          value: p.filter,
                                          onChanged: p.setFilter,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                    child: _NotificationsBody(provider: p),
                                  ),
                                ],
                              ),
                            ),
                            if (p.loadingMore) ...[
                              const SizedBox(height: 12),
                              const _LoadMoreBar(),
                            ] else if (!p.hasMore && p.items.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const _EndHint(),
                            ],
                            const SizedBox(height: 10),
                            Text(
                              'Источник: /api/fcm/notifications/ (page, page_size, is_read=0/1).',
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                                color: _greyText,
                              ),
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
        },
      ),
    );
  }
}

class _NotificationsBody extends StatelessWidget {
  const _NotificationsBody({required this.provider});

  final NotificationsProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.loading) {
      return Column(
        children: List.generate(6, (i) => const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: _NotificationSkeleton(),
        )),
      );
    }

    if (provider.error != null && provider.items.isEmpty) {
      return _InlineError(
        text: provider.error!,
        onRetry: provider.loadInitial,
      );
    }

    if (provider.items.isEmpty) {
      final text = provider.filter == NotificationsReadFilter.unread
          ? 'Непрочитанных уведомлений нет.'
          : 'Уведомлений пока нет.';
      return _EmptyBlock(text: text, onRefresh: provider.refresh);
    }

    return Column(
      children: [
        for (final n in provider.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NotificationCard(n: n),
          ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.n});

  final AppNotificationModel n;

  static const _tileBorder = Color(0xFFE9EDF2);
  static const _accent = Color(0xFFFF8A00);
  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(n.channel);
    final meta = _formatTime(n.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: n.isRead ? Colors.white : const Color(0xFFFFF7EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _tileBorder, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: n.isRead ? const Color(0xFFF7F8FA) : const Color(0xFFFFE6CC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _tileBorder, width: 1),
                ),
                child: Icon(icon, size: 22, color: Colors.black),
              ),
              if (!n.isRead)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        n.title.isEmpty ? 'Уведомление' : n.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      meta,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.0,
                        fontWeight: FontWeight.w600,
                        color: _greyText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  n.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5F6670),
                  ),
                ),
                if (n.channel.isNotEmpty || n.type.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _Tag(text: n.channel.isEmpty ? 'channel' : n.channel),
                      const SizedBox(width: 8),
                      _Tag(text: n.type.isEmpty ? 'type' : n.type),
                      const Spacer(),
                      Text(
                        n.isRead ? 'Прочитано' : 'Новое',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.0,
                          fontWeight: FontWeight.w800,
                          color: n.isRead ? const Color(0xFF9FA4AD) : _accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String channel) {
    switch (channel) {
      case 'orders':
        return Icons.local_shipping_rounded;
      case 'system':
        return Icons.shield_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day);
    final d1 = DateTime(dt.year, dt.month, dt.day);

    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');

    if (d0 == d1) return '$hh:$mm';

    final diffDays = d0.difference(d1).inDays;
    if (diffDays == 1) return 'Вчера $hh:$mm';

    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$dd.$mo $hh:$mm';
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          height: 1.0,
          fontWeight: FontWeight.w700,
          color: Color(0xFF5F6670),
        ),
      ),
    );
  }
}

class _UnreadPill extends StatelessWidget {
  const _UnreadPill({required this.count});

  final int count;

  static const _accent = Color(0xFFFF8A00);

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE9EDF2)),
        ),
        child: const Text(
          '0',
          style: TextStyle(
            fontSize: 12,
            height: 1.0,
            fontWeight: FontWeight.w900,
            color: Color(0xFF9FA4AD),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFDAB8)),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 12,
          height: 1.0,
          fontWeight: FontWeight.w900,
          color: _accent,
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.value,
    required this.onChanged,
  });

  final NotificationsReadFilter value;
  final ValueChanged<NotificationsReadFilter> onChanged;

  static const _accent = Color(0xFFFF8A00);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilterChip(
            text: NotificationsReadFilter.all.label(),
            active: value == NotificationsReadFilter.all,
            onTap: () => onChanged(NotificationsReadFilter.all),
          ),
          _FilterChip(
            text: NotificationsReadFilter.unread.label(),
            active: value == NotificationsReadFilter.unread,
            onTap: () => onChanged(NotificationsReadFilter.unread),
          ),
          _FilterChip(
            text: NotificationsReadFilter.read.label(),
            active: value == NotificationsReadFilter.read,
            onTap: () => onChanged(NotificationsReadFilter.read),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.text,
    required this.active,
    required this.onTap,
  });

  final String text;
  final bool active;
  final VoidCallback onTap;

  static const _accent = Color(0xFFFF8A00);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFF1E3) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            height: 1.0,
            fontWeight: FontWeight.w900,
            color: active ? _accent : const Color(0xFF5F6670),
          ),
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.text, required this.onRefresh});

  final String text;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inbox_rounded, size: 20, color: Color(0xFF9FA4AD)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5F6670),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onRefresh,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE9EDF2)),
              ),
              child: const Text(
                'Обновить',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.text, required this.onRetry});

  final String text;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD1D1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 20, color: Color(0xFFB00020)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B1B1B),
              ),
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFFFD1D1)),
              ),
              child: const Text(
                'Повторить',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreBar extends StatelessWidget {
  const _LoadMoreBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            'Загружаем ещё…',
            style: TextStyle(
              fontSize: 13,
              height: 1.0,
              fontWeight: FontWeight.w800,
              color: Color(0xFF5F6670),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndHint extends StatelessWidget {
  const _EndHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      child: const Text(
        'Это всё — дальше уведомлений нет.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: Color(0xFF9FA4AD),
        ),
      ),
    );
  }
}

class _NotificationSkeleton extends StatelessWidget {
  const _NotificationSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9EDF2)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2F6),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFFEFF2F6), borderRadius: BorderRadius.circular(999))),
                const SizedBox(height: 10),
                Container(height: 10, width: 240, decoration: BoxDecoration(color: const Color(0xFFEFF2F6), borderRadius: BorderRadius.circular(999))),
              ],
            ),
          ),
        ],
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
