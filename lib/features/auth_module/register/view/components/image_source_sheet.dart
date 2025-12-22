import 'package:flutter/material.dart';

import '../widgets/image_source_tile_widget.dart';

class ImageSourceSheet extends StatelessWidget {
  const ImageSourceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x29000000),
            blurRadius: 30,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 52,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E9EF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Загрузить документ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Выберите источник фотографии',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.25,
                color: Color(0xFF9FA4AD),
              ),
            ),
            const SizedBox(height: 18),
            ImageSourceTile(
              icon: Icons.photo_camera_rounded,
              title: 'Сделать фото',
              subtitle: 'Использовать камеру',
              onTap: () => Navigator.of(context).pop(ImageSourceType.camera),
            ),
            const SizedBox(height: 10),
            ImageSourceTile(
              icon: Icons.photo_library_rounded,
              title: 'Выбрать из галереи',
              subtitle: 'Использовать сохранённое фото',
              onTap: () => Navigator.of(context).pop(ImageSourceType.gallery),
            ),
          ],
        ),
      ),
    );
  }
}