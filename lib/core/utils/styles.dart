import 'package:flutter/painting.dart';

import '../design/app_colors.dart';
import '../design/app_typography.dart';

/// Обратная совместимость: типографика переехала в
/// `core/design/app_typography.dart`.
///
/// Имена сохранены (используются в `select_role_screen`,
/// `confirm_whatsapp_code_screen`, `carrier_title_block_widget`), но значения
/// теперь берутся из [AppTypography]. Заодно убраны опасные `height: 0.2`,
/// из-за которых текст обрезался при системном масштабе 1.4.
class AppTextStyles {
  const AppTextStyles._();

  static const TextStyle titleBlackStyle = AppTypography.screenTitleCompact;

  static final TextStyle titleGreyStyle = AppTypography.screenTitleCompact
      .copyWith(color: AppColors.textTertiary);

  static const TextStyle cardTitleStyle = AppTypography.cardTitle;

  static const TextStyle cardSubtitleStyle = AppTypography.caption;

  static const TextStyle subtitleStyle = AppTypography.captionMuted;
}
