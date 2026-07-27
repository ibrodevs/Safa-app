import 'package:flutter/material.dart';

import '../../design/app_design.dart';
import '../../utils/friendly_error.dart';
import '../buttons/app_buttons.dart';

/// Пустое состояние: иконка, короткий текст, основное действие.
///
/// Заменяет пустые белые экраны и одинокие серые строки.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Вариант для встраивания в карточку.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _StateLayout(
      icon: icon,
      iconColor: AppColors.textTertiary,
      iconBackground: AppColors.surfaceMuted,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      compact: compact,
    );
  }
}

/// Состояние ошибки: понятное сообщение + кнопка повторной загрузки.
///
/// Технический текст не показывается никогда: [error] прогоняется через
/// [friendlyErrorMessage].
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.error,
    this.title = 'Не удалось загрузить',
    this.onRetry,
    this.retryLabel = 'Повторить',
    this.compact = false,
  });

  final Object? error;
  final String title;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final message = friendlyErrorMessage(error);
    final isOffline = message == kOfflineErrorMessage;

    return _StateLayout(
      icon: isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
      iconColor: AppColors.error,
      iconBackground: AppColors.errorSoft,
      title: isOffline ? 'Нет соединения' : title,
      message: message,
      actionLabel: onRetry == null ? null : retryLabel,
      onAction: onRetry,
      compact: compact,
    );
  }
}

/// Индикатор загрузки с пояснением. Не блокирует экран без необходимости.
class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key, this.message, this.compact = false});

  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: compact ? AppSpacing.lg : AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            if (message != null && message!.isNotEmpty) ...[
              AppSpacing.gapSm,
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTypography.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Прямоугольник-заглушка для skeleton-загрузки.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius = AppRadius.allSm,
  });

  final double height;
  final double? width;
  final BorderRadius borderRadius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.45,
        end: 1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }
}

/// Skeleton-карточка списка заказов.
class AppOrderCardSkeleton extends StatelessWidget {
  const AppOrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.allLg,
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppSkeleton(width: 110, height: 12),
              Spacer(),
              AppSkeleton(width: 74, height: 20),
            ],
          ),
          AppSpacing.gapSm,
          AppSkeleton(width: 180, height: 18),
          AppSpacing.gapSm,
          AppSkeleton(height: 12),
          AppSpacing.gapXs,
          AppSkeleton(width: 140, height: 12),
        ],
      ),
    );
  }
}

class _StateLayout extends StatelessWidget {
  const _StateLayout({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.compact,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double iconBox = compact ? 48 : 64;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: compact ? AppSpacing.lg : AppSpacing.xxl,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: iconBox * 0.45, color: iconColor),
              ),
              AppSpacing.gapMd,
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.cardTitle,
              ),
              if (message != null && message!.isNotEmpty) ...[
                AppSpacing.gapXs,
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                AppSpacing.gapLg,
                AppPrimaryButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  size: AppButtonSize.medium,
                  expand: false,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
