import 'package:flutter/material.dart';

import '../../../../../core/design/app_design.dart';
import 'upload_tile.dart';

/// Блок загрузки удостоверения личности.
///
/// На узких экранах плитки выкладываются в столбик — раньше жёсткий `Row`
/// c двумя плитками по 120 px переполнялся на 320 px.
class IdCardBlock extends StatelessWidget {
  const IdCardBlock({
    super.key,
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
    final front = UploadTile(
      title: 'Лицевая сторона',
      onTap: onFront,
      imagePath: frontPath,
      placeholderAsset: 'assets/icons/ic_front_id_card.svg',
    );
    final back = UploadTile(
      title: 'Обратная сторона',
      onTap: onBack,
      imagePath: backPath,
      placeholderAsset: 'assets/icons/ic_back_id_card.svg',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 320) {
          return Column(children: [front, AppSpacing.gapSm, back]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: front),
            AppSpacing.hGapSm,
            Expanded(child: back),
          ],
        );
      },
    );
  }
}
