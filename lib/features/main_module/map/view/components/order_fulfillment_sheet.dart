import 'package:flutter/material.dart';

class OrderFulfillmentSheet extends StatelessWidget {
  const OrderFulfillmentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
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
              color: Color(0xFF43c432),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 24),

          _StopItem(
            title: 'Контейнер 74, 8 проход',
            subtitle: 'Алкан базары',
            trailing: _TrailingStatus(
              text: 'Забрали груз',
              color: Color(0xFFB7BCC5),
            ),
            isActive: false,
          ),

          const SizedBox(height: 12),
          const _ArrowDown(),
          const SizedBox(height: 12),

          _StopItem(
            title: 'Контейнер 19, 9 проход',
            subtitle: 'Кытай базары',
            trailing: _TrailingStatus(
              text: 'Вы здесь',
              color: Color(0xFF41C44B),
              isActive: true,
            ),
            isActive: true,
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 40,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF28C28),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
    );
  }
}

class _StopItem extends StatelessWidget {
  const _StopItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.isActive,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final bool isActive;

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
        const SizedBox(width: 10),
        trailing,
      ],
    );
  }
}

class _TrailingStatus extends StatelessWidget {
  const _TrailingStatus({
    required this.text,
    required this.color,
    this.isActive = false,
  });

  final String text;
  final Color color;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 2,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
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
          Icons.keyboard_arrow_down_rounded,
          size: 28,
          color: Colors.black,
        ),
      ),
    );
  }
}
