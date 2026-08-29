import 'package:flutter/material.dart';

import '../../design/app_design.dart';

/// Роль точки в маршруте.
enum RoutePointRole {
  /// Начальная точка — обязательная.
  start,

  /// Промежуточная остановка — можно удалить и переставить.
  stop,

  /// Конечная точка — обязательная.
  end,
}

/// Строка точки маршрута с вертикальной соединительной линией.
///
/// ```text
/// ● Откуда
/// │
/// ● Куда
/// ```
///
/// Один компонент используется и в конструкторе маршрута, и в итоговой
/// карточке заказа, и в детальном экране — раньше это были три разных
/// визуальных языка (стрелки вниз, нумерованный текст, столбик-полоска).
class AppRoutePointTile extends StatelessWidget {
  const AppRoutePointTile({
    super.key,
    required this.role,
    required this.title,
    this.subtitle,
    this.index,
    this.placeholder = false,
    this.isLast = false,
    this.onTap,
    this.onRemove,
    this.trailing,
    this.dense = false,
  });

  final RoutePointRole role;
  final String title;
  final String? subtitle;

  /// Номер остановки (показывается для [RoutePointRole.stop]).
  final int? index;

  /// Точка ещё не выбрана — заголовок показывается как подсказка.
  final bool placeholder;

  /// Последняя точка — соединительная линия не рисуется.
  final bool isLast;

  final VoidCallback? onTap;

  /// Удаление доступно только для промежуточных точек.
  final VoidCallback? onRemove;
  final Widget? trailing;
  final bool dense;

  Color get _dotColor {
    if (placeholder) return AppColors.borderStrong;
    switch (role) {
      case RoutePointRole.start:
        return AppColors.success;
      case RoutePointRole.stop:
        return AppColors.info;
      case RoutePointRole.end:
        return AppColors.primary;
    }
  }

  String get _roleLabel {
    switch (role) {
      case RoutePointRole.start:
        return 'Откуда';
      case RoutePointRole.stop:
        return index == null ? 'Остановка' : 'Остановка $index';
      case RoutePointRole.end:
        return 'Куда';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canRemove = role == RoutePointRole.stop && onRemove != null;

    // IntrinsicHeight нужен, чтобы соединительная линия маркера растянулась
    // ровно на высоту текстового блока — без фиксированных высот.
    final content = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RouteMarker(
            color: _dotColor,
            isLast: isLast,
            label: role == RoutePointRole.stop ? '${index ?? ''}' : null,
            dense: dense,
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : (dense ? AppSpacing.sm : AppSpacing.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_roleLabel, style: AppTypography.label),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.cardTitle.copyWith(
                      color: placeholder
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                      fontWeight: placeholder
                          ? FontWeight.w500
                          : FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null &&
                      subtitle!.trim().isNotEmpty &&
                      subtitle!.trim() != title.trim()) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (trailing != null)
            Align(alignment: Alignment.topRight, child: trailing!)
          else ...[
            if (onTap != null)
              const Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(top: AppSpacing.lg),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            if (canRemove)
              Align(
                alignment: Alignment.topRight,
                child: Semantics(
                  button: true,
                  label: 'Удалить $_roleLabel',
                  child: InkWell(
                    onTap: onRemove,
                    borderRadius: AppRadius.allFull,
                    child: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Semantics(
      button: true,
      label: '$_roleLabel. $title',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allSm,
        child: content,
      ),
    );
  }
}

class _RouteMarker extends StatelessWidget {
  const _RouteMarker({
    required this.color,
    required this.isLast,
    required this.label,
    required this.dense,
  });

  final Color color;
  final bool isLast;
  final String? label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final hasLabel = label != null && label!.isNotEmpty;

    return SizedBox(
      width: 20,
      child: Column(
        children: [
          SizedBox(height: dense ? AppSpacing.md : AppSpacing.lg),
          Container(
            width: hasLabel ? 18 : 12,
            height: hasLabel ? 18 : 12,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasLabel ? color : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2.5),
            ),
            child: hasLabel
                ? Text(
                    label!,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 9,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  )
                : null,
          ),
          if (!isLast)
            Expanded(
              child: Container(
                width: 2,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadius.allFull,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
