import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/widgets/app_widgets.dart';

enum ImageSourceType { camera, gallery }

/// Строка выбора источника фотографии.
class ImageSourceTile extends StatelessWidget {
  const ImageSourceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      shadows: AppShadows.none,
      borderRadius: AppRadius.allMd,
      child: AppListTile(
        title: title,
        subtitle: subtitle,
        icon: icon,
        onTap: onTap,
      ),
    );
  }
}
