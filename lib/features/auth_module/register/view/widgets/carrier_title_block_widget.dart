import 'package:flutter/material.dart';

class CarrierTitleBlock extends StatelessWidget {
  const CarrierTitleBlock({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Регистрация',
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            height: 1.1,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Данные клиента',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1.15,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Станьте тачкистом и получите дополнительно\nновых клиентов ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: Color(0xFF9FA4AD),
          ),
        ),
      ],
    );
  }
}