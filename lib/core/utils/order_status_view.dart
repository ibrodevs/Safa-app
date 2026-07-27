import 'package:flutter/material.dart';

import '../widgets/common/app_status_badge.dart';

/// Группа статуса — для вкладок списка заказов.
enum OrderStatusGroup { active, completed, canceled }

/// Представление статуса заказа: человеческий текст, тон бейджа и иконка.
///
/// Раньше в проекте было две идентичные копии `_mapStatus` (в списке истории
/// и в детальном экране), и обе красили любой статус — включая «Отменено» —
/// в один и тот же зелёный цвет. Теперь статус читается и по тексту,
/// и по иконке, а цвет — только дополнительный признак.
///
/// Коды статусов не меняются: они приходят с backend как есть
/// (`pending`, `assigned`/`accepted`, `in_transit`/`in_progress`,
/// `completed`/`delivered`, `canceled`).
@immutable
class OrderStatusView {
  const OrderStatusView({
    required this.code,
    required this.label,
    required this.tone,
    required this.icon,
    required this.group,
  });

  final String code;
  final String label;
  final AppBadgeTone tone;
  final IconData icon;
  final OrderStatusGroup group;

  bool get isActive => group == OrderStatusGroup.active;
  bool get isTerminal => group != OrderStatusGroup.active;

  static OrderStatusView of(String rawCode) {
    final code = rawCode.trim().toLowerCase();

    switch (code) {
      case 'new':
      case 'created':
        return OrderStatusView(
          code: code,
          label: 'Новый',
          tone: AppBadgeTone.info,
          icon: Icons.fiber_new_outlined,
          group: OrderStatusGroup.active,
        );
      case 'pending':
        return OrderStatusView(
          code: code,
          label: 'Поиск исполнителя',
          tone: AppBadgeTone.warning,
          icon: Icons.search_rounded,
          group: OrderStatusGroup.active,
        );
      case 'assigned':
      case 'accepted':
        return OrderStatusView(
          code: code,
          label: 'Назначен',
          tone: AppBadgeTone.info,
          icon: Icons.person_outline_rounded,
          group: OrderStatusGroup.active,
        );
      case 'in_transit':
      case 'in_progress':
        return OrderStatusView(
          code: code,
          label: 'В пути',
          tone: AppBadgeTone.primary,
          icon: Icons.local_shipping_outlined,
          group: OrderStatusGroup.active,
        );
      case 'completed':
      case 'delivered':
        return OrderStatusView(
          code: code,
          label: 'Выполнен',
          tone: AppBadgeTone.success,
          icon: Icons.check_circle_outline_rounded,
          group: OrderStatusGroup.completed,
        );
      case 'canceled':
      case 'cancelled':
        return OrderStatusView(
          code: code,
          label: 'Отменён',
          tone: AppBadgeTone.error,
          icon: Icons.cancel_outlined,
          group: OrderStatusGroup.canceled,
        );
      default:
        return OrderStatusView(
          code: code,
          label: rawCode.trim().isEmpty ? 'Статус неизвестен' : rawCode.trim(),
          tone: AppBadgeTone.neutral,
          icon: Icons.help_outline_rounded,
          group: OrderStatusGroup.active,
        );
    }
  }

  /// Готовый бейдж статуса.
  AppStatusBadge toBadge({bool dense = false}) =>
      AppStatusBadge(label: label, tone: tone, icon: icon, dense: dense);
}

/// Вкладки фильтра списка заказов.
enum OrderFilter {
  all('Все'),
  active('Активные'),
  completed('Завершённые'),
  canceled('Отменённые');

  const OrderFilter(this.label);

  final String label;

  bool matches(String statusCode) {
    if (this == OrderFilter.all) return true;
    final group = OrderStatusView.of(statusCode).group;
    switch (this) {
      case OrderFilter.active:
        return group == OrderStatusGroup.active;
      case OrderFilter.completed:
        return group == OrderStatusGroup.completed;
      case OrderFilter.canceled:
        return group == OrderStatusGroup.canceled;
      case OrderFilter.all:
        return true;
    }
  }
}
