import 'package:dogo/features/main_module/home/components/tag_chip_widget.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/app_colors.dart';

class SmallFeatureCard extends StatelessWidget {
  const SmallFeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tagText,
    required this.imageAsset,
    this.imagePadding = 10,
    this.imagePadding2 = 0,
    required this.onTap,
    this.imageHeight = 70,
    this.imageScale = 1.0,
  });

  final String title;
  final String subtitle;
  final String tagText;
  final String imageAsset;
  final VoidCallback onTap;

  final double imageHeight;
  final double imagePadding;
  final double imagePadding2;
  final double imageScale;

  static const double _radius = 20;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: AppColors.tileBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height:imagePadding2),
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: imageHeight,
                  child: Transform.scale(
                    scale: imageScale,
                    alignment: Alignment.topLeft,
                    child: Image.asset(imageAsset, fit: BoxFit.contain),
                  ),
                ),
              ),
              SizedBox(height:imagePadding),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                  color: AppColors.greyText,
                ),
              ),
              const SizedBox(height: 16),
              TagChip(text: tagText, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}
