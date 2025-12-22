import 'package:flutter/material.dart';

import 'upload_tile.dart';

class IdCardBlock extends StatelessWidget {
  const IdCardBlock({
    required this.onFront,
    required this.onBack,
    this.frontPath,
    this.backPath,
  });

  final VoidCallback onFront;
  final VoidCallback onBack;
  final String? frontPath;
  final String? backPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ID Card',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Нажмите и загрузите документ с двух сторон',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: Color(0xFF9FA4AD),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: UploadTile(
                  title: 'Лицевая сторона',
                  onTap: onFront,
                  imagePath: frontPath,
                  placeholderAsset: 'assets/icons/ic_front_id_card.svg',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: UploadTile(
                  title: 'Обратная сторона',
                  onTap: onBack,
                  imagePath: backPath,
                  placeholderAsset: 'assets/icons/ic_back_id_card.svg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

