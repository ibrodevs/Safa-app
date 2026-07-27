import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../../core/design/app_design.dart';

/// Плитка загрузки фотографии документа.
class UploadTile extends StatelessWidget {
  const UploadTile({
    super.key,
    required this.title,
    required this.onTap,
    this.imagePath,
    required this.placeholderAsset,
  });

  final String title;
  final VoidCallback onTap;
  final String? imagePath;
  final String placeholderAsset;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return Semantics(
      button: true,
      label: hasImage ? '$title, загружено' : '$title, загрузить',
      child: Material(
        color: hasImage ? AppColors.surfaceMuted : AppColors.surface,
        borderRadius: AppRadius.allMd,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 116,
            decoration: BoxDecoration(
              borderRadius: AppRadius.allMd,
              border: Border.all(
                color: hasImage
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.border,
              ),
            ),
            child: hasImage ? _preview() : _placeholder(),
          ),
        ),
      ),
    );
  }

  Widget _preview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          File(imagePath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs + 2,
            ),
            color: AppColors.black.withValues(alpha: 0.45),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: AppColors.white,
                ),
                AppSpacing.hGapXxs,
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.badge.copyWith(color: AppColors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppRadius.allXs,
            ),
            child: SvgPicture.asset(
              placeholderAsset,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              placeholderBuilder: (_) => const Icon(
                Icons.badge_outlined,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ),
          AppSpacing.gapXs,
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text('Нажмите, чтобы загрузить', style: AppTypography.captionMuted),
        ],
      ),
    );
  }
}
