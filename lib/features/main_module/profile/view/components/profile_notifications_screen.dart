import 'package:dogo/core/utils/app_colors.dart';
import 'package:dogo/data/network/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/model/app_notification_model.dart';
import '../../data/repo/notifications_repo.dart';
import '../../provider/notifications_provider.dart';

class ProfileNotificationsScreen extends StatefulWidget {
  const ProfileNotificationsScreen({super.key, this.role = 'client'});

  final String role;

  bool get isCarrier => role == 'carrier';

  @override
  State<ProfileNotificationsScreen> createState() =>
      _ProfileNotificationsScreenState();
}

class _ProfileNotificationsScreenState
    extends State<ProfileNotificationsScreen> {
  late final ScrollController _scrollController;

  bool _newShipments = true;
  bool _statusUpdates = true;
  bool _promo = false;
  bool _system = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final provider = context.read<NotificationsProvider>();
    if (provider.loading || provider.loadingMore || !provider.hasMore) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      provider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = NotificationsProvider(
          NotificationsRepository(ApiService.instance),
        );
        provider.loadInitial();
        return provider;
      },
      child: Builder(
        builder: (context) {
          final provider = context.watch<NotificationsProvider>();
          return Scaffold(
            backgroundColor: const Color(0xFFF7F8FA),
            appBar: AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
              title: const Text(
                'Уведомления',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: _UnreadBadge(count: provider.unreadCount),
                  ),
                ),
              ],
            ),
            body: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: provider.refresh,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  _SectionCard(
                    title: 'Настройки',
                    child: Column(
                      children: [
                        if (widget.isCarrier) ...[
                          _NotificationSettingTile(
                            icon: Icons.local_shipping_outlined,
                            title: 'Новые заказы рядом',
                            subtitle:
                                'Подходящие заказы для вашего типа работы.',
                            value: _newShipments,
                            onChanged: (value) {
                              setState(() => _newShipments = value);
                            },
                          ),
                          const Divider(height: 1),
                        ],
                        _NotificationSettingTile(
                          icon: Icons.sync_rounded,
                          title: 'Статусы заказов',
                          subtitle:
                              'Принятие, выполнение, завершение и отмена.',
                          value: _statusUpdates,
                          onChanged: (value) {
                            setState(() => _statusUpdates = value);
                          },
                        ),
                        const Divider(height: 1),
                        _NotificationSettingTile(
                          icon: Icons.local_offer_outlined,
                          title: 'Акции и бонусы',
                          subtitle: 'Промокоды и специальные предложения.',
                          value: _promo,
                          onChanged: (value) {
                            setState(() => _promo = value);
                          },
                        ),
                        const Divider(height: 1),
                        _NotificationSettingTile(
                          icon: Icons.shield_outlined,
                          title: 'Системные уведомления',
                          subtitle: 'Важная информация о работе Safa.',
                          value: _system,
                          onChanged: (value) {
                            setState(() => _system = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'История',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      _ReadFilter(
                        value: provider.filter,
                        onChanged: provider.setFilter,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _NotificationsContent(provider: provider),
                  if (provider.loadingMore) ...[
                    const SizedBox(height: 14),
                    const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    ),
                  ],
                  if (!provider.hasMore && provider.items.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Center(
                      child: Text(
                        'Это все уведомления',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E9ED)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _NotificationSettingTile extends StatelessWidget {
  const _NotificationSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF4B5563)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: Color(0xFF8A9099),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _NotificationsContent extends StatelessWidget {
  const _NotificationsContent({required this.provider});

  final NotificationsProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.loading) {
      return const _LoadingNotifications();
    }

    if (provider.error != null && provider.items.isEmpty) {
      return _StateCard(
        icon: Icons.error_outline_rounded,
        title: 'Не удалось загрузить уведомления',
        subtitle: provider.error!,
        action: TextButton(
          onPressed: provider.loadInitial,
          child: const Text('Повторить'),
        ),
      );
    }

    if (provider.items.isEmpty) {
      return _StateCard(
        icon: Icons.notifications_none_rounded,
        title: 'Уведомлений пока нет',
        subtitle: provider.filter == NotificationsReadFilter.unread
            ? 'Все уведомления уже прочитаны.'
            : 'Новые события появятся здесь.',
      );
    }

    return Column(
      children: [
        for (var i = 0; i < provider.items.length; i++) ...[
          _NotificationCard(
            notification: provider.items[i],
            onTap: () => provider.markRead(provider.items[i].id),
          ),
          if (i != provider.items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final AppNotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(notification.channel, notification.type);
    final time = _formatTime(notification.createdAt);

    return Material(
      color: notification.isRead ? Colors.white : const Color(0xFFFFF8F1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7E9ED)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 21, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title.trim().isEmpty
                                ? 'Уведомление'
                                : notification.title.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    if (notification.body.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        notification.body.trim(),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF5F6670),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      notification.isRead ? 'Прочитано' : 'Новое',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: notification.isRead
                            ? const Color(0xFF9CA3AF)
                            : AppColors.primary,
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

  IconData _iconFor(String channel, String type) {
    final value = '$channel $type'.toLowerCase();
    if (value.contains('payment')) return Icons.payments_outlined;
    if (value.contains('shipment') || value.contains('order')) {
      return Icons.local_shipping_outlined;
    }
    if (value.contains('promo') || value.contains('bonus')) {
      return Icons.local_offer_outlined;
    }
    return Icons.notifications_outlined;
  }

  String _formatTime(DateTime value) {
    final now = DateTime.now();
    final local = value.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(local.year, local.month, local.day);
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    if (date == today) return '$hour:$minute';
    if (today.difference(date).inDays == 1) return 'Вчера';

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day.$month';
  }
}

class _ReadFilter extends StatelessWidget {
  const _ReadFilter({required this.value, required this.onChanged});

  final NotificationsReadFilter value;
  final ValueChanged<NotificationsReadFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<NotificationsReadFilter>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => NotificationsReadFilter.values
          .map(
            (item) => PopupMenuItem<NotificationsReadFilter>(
              value: item,
              child: Text(item.label()),
            ),
          )
          .toList(growable: false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7E9ED)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.label(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 30),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: count > 0 ? const Color(0xFFFFEFE0) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: count > 0 ? AppColors.primary : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E9ED)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: const Color(0xFF9CA3AF)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Color(0xFF8A9099),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 8),
            action!,
          ],
        ],
      ),
    );
  }
}

class _LoadingNotifications extends StatelessWidget {
  const _LoadingNotifications();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 3 ? 0 : 10),
          child: Container(
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7E9ED)),
            ),
          ),
        ),
      ),
    );
  }
}
