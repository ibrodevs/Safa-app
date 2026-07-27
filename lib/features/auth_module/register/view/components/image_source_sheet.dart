import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../widgets/image_source_tile_widget.dart';

/// Выбор источника фотографии документа.
///
/// Переведён на общий [AppBottomSheet]: единый радиус, drag handle,
/// безопасные отступы, корректная работа с клавиатурой.
class ImageSourceSheet extends StatelessWidget {
  const ImageSourceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'Загрузить документ',
      subtitle: 'Выберите источник фотографии',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ImageSourceTile(
            icon: Icons.photo_camera_outlined,
            title: 'Сделать фото',
            subtitle: 'Использовать камеру',
            onTap: () => Navigator.of(context).pop(ImageSourceType.camera),
          ),
          AppSpacing.gapXs,
          ImageSourceTile(
            icon: Icons.photo_library_outlined,
            title: 'Выбрать из галереи',
            subtitle: 'Использовать сохранённое фото',
            onTap: () => Navigator.of(context).pop(ImageSourceType.gallery),
          ),
        ],
      ),
    );
  }
}
