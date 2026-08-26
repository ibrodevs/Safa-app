import 'package:flutter/material.dart';

import 'header_empty_row.dart';

/// Содержимое экрана ожидания заказов.
///
/// Вынесено из `EmptyOrdersScreen` отдельным виджетом, чтобы вёрстку можно
/// было проверять тестом на разных размерах экрана без сети и провайдеров.
///
/// `SliverFillRemaining` даёт колонке устойчивую высоту вьюпорта и при этом
/// разрешает прокрутку на очень маленьком экране. Это не ломается во время
/// pull-to-refresh, в отличие от связки IntrinsicHeight + scroll view.
class CarrierEmptyState extends StatelessWidget {
  const CarrierEmptyState({
    super.key,
    required this.greeting,
    required this.onLeaveLine,
    this.avatarUrl,
  });

  final String greeting;
  final String? avatarUrl;
  final VoidCallback onLeaveLine;

  static const EdgeInsets _padding = EdgeInsets.fromLTRB(24, 28, 24, 24);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverPadding(
          padding: _padding,
          sliver: SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderEmptyRow(avatarUrl: avatarUrl, title: greeting),
                const Spacer(flex: 3),
                const Center(
                  child: Text(
                    'Пока нет активных\nзаказов',
                    style: TextStyle(
                      fontSize: 21,
                      fontFamily: 'SFProDisplay',
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(flex: 2),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: onLeaveLine,
                    icon: const Icon(Icons.power_settings_new_rounded),
                    label: const Text(
                      'Выйти с линии',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
