import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/utils/app_colors.dart';

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.text,
    this.iconAsset,
    this.compact = false,
    this.width,
  });

  final String text;
  final String? iconAsset;
  final bool compact;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 9.17, vertical: 0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE6D2),
        borderRadius: BorderRadius.circular(4.89),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (iconAsset != null) ...[
              SvgPicture.asset(
                iconAsset!,
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  AppColors.accent,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 3.06),
            ],
            Text(
              text,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.accent,
                letterSpacing: 0.055,
                height: 0.778,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
