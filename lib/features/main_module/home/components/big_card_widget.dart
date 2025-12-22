import 'package:dogo/core/utils/app_colors.dart';
import 'package:dogo/features/main_module/home/components/tag_chip_widget.dart';
import 'package:dogo/features/main_module/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class BigFeatureCard extends StatelessWidget {
  const BigFeatureCard({
    required this.title,
    required this.subtitle,
    required this.tagText,
    required this.imageAsset,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String tagText;
  final String imageAsset;
  final VoidCallback onTap;

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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: AppColors.tileBorder, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                          color: AppColors.greyText,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const SizedBox(height: 2),
                      TagChip(text: tagText),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 140,
                height: 120,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
