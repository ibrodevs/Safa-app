import 'package:flutter/material.dart';

import '../../design/app_design.dart';

/// Аватар пользователя: сеть → ассет-заглушка → инициал.
///
/// Заменяет две отдельные реализации (`home/components/avatar_widget.dart`
/// и `profile_screen::_Avatar`).
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, this.url, this.name, this.size = 44, this.onTap});

  final String? url;

  /// Имя, из которого берётся инициал, если картинки нет.
  final String? name;
  final double size;
  final VoidCallback? onTap;

  String get _initial {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = url?.trim();
    final hasUrl = resolvedUrl != null && resolvedUrl.isNotEmpty;

    Widget content = hasUrl
        ? Image.network(
            resolvedUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return _placeholder();
            },
          )
        : _fallback();

    content = ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(width: size, height: size, child: content),
    );

    content = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: content,
    );

    if (onTap == null) return content;

    return Semantics(
      button: true,
      label: 'Профиль',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: content,
      ),
    );
  }

  Widget _placeholder() => ColoredBox(
    color: AppColors.surfaceMuted,
    child: SizedBox(width: size, height: size),
  );

  Widget _fallback() {
    return Image.asset(
      AppImages.avatarPlaceholder,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: AppColors.primarySoft,
        alignment: Alignment.center,
        child: Text(
          _initial,
          style: AppTypography.cardTitle.copyWith(
            color: AppColors.primaryPressed,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}
