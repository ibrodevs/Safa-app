import 'package:flutter/material.dart';
import '../../data/model/delivery_point_model.dart';

class OrderFulfillmentSheet extends StatelessWidget {
  const OrderFulfillmentSheet({
    super.key,
    required this.stops,
  });

  final List<DeliveryPoint> stops;

  static const _green = Color(0xFF41C44B);
  static const _grey = Color(0xFFB7BCC5);

  String _titleForStop(DeliveryPoint s) {
    final c = (s.container ?? '').trim();
    final p = (s.passage ?? '').trim();

    if (c.isNotEmpty && p.isNotEmpty) return 'Контейнер $c, $p проход';
    if (c.isNotEmpty) return 'Контейнер $c';
    if (p.isNotEmpty) return '$p проход';

    return s.title;
  }

  String _subtitleForStop(DeliveryPoint s) {
    final b = (s.bazar ?? '').trim();
    if (b.isNotEmpty) return b;
    return s.subtitle;
  }

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.white,
      elevation: 10,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Заказ выполняется',
              style: TextStyle(
                fontSize: 27,
                fontFamily: 'SFProDisplay',
                fontWeight: FontWeight.w600,
                color: Color(0xFF43C432),
                height: 1.15,
              ),
            ),
            const SizedBox(height: 24),

            for (int i = 0; i < stops.length; i++) ...[
              _StopItem(
                title: _titleForStop(stops[i]),
                subtitle: _subtitleForStop(stops[i]),
                trailing: _buildTrailing(i),
              ),
              if (i != stops.length - 1) ...[
                const SizedBox(height: 12),
                const _ArrowDown(),
                const SizedBox(height: 12),
              ] else ...[
                const SizedBox(height: 18),
              ],
            ],

            SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF28C28),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'В процессе',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailing(int index) {
    final isFirst = index == 0;
    final isLast = index == stops.length - 1;

    if (isFirst) {
      return const _TrailingStatus(text: 'Вы здесь', color: _green);
    }
    if (isLast) {
      return const _TrailingStatus(text: 'Забрали груз', color: _grey);
    }

    return const SizedBox(width: 110, height: 40);
  }
}

class _StopItem extends StatelessWidget {
  const _StopItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9AA0A6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        trailing,
      ],
    );
  }
}

class _TrailingStatus extends StatelessWidget {
  const _TrailingStatus({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 2,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ArrowDown extends StatelessWidget {
  const _ArrowDown();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(left: 6),
        child: Icon(
          Icons.arrow_downward_rounded,
          size: 28,
          color: Colors.black,
        ),
      ),
    );
  }
}
