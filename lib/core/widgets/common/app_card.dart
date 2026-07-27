import 'package:flutter/material.dart';

import '../../design/app_design.dart';

/// Базовая карточка: белый фон, светлая граница, очень слабая тень.
///
/// При [onTap] добавляется лёгкая анимация нажатия (150 ms).
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color = AppColors.surface,
    this.borderColor = AppColors.border,
    this.borderRadius = AppRadius.allLg,
    this.shadows = AppShadows.card,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color? borderColor;
  final BorderRadius borderRadius;
  final List<BoxShadow> shadows;
  final String? semanticLabel;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: AppDurations.fast,
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: widget.borderRadius,
          border: widget.borderColor == null
              ? null
              : Border.all(color: widget.borderColor!),
          boxShadow: widget.shadows,
        ),
        child: Padding(padding: widget.padding, child: widget.child),
      ),
    );

    if (widget.onTap != null) {
      content = Semantics(
        button: true,
        label: widget.semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}
