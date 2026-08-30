import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/design/app_design.dart';
import '../../../../core/utils/friendly_error.dart';
import '../../../../core/utils/kg_phone_format.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../data/network/api_service.dart';
import '../../../../data/services/logout_service.dart';
import '../provider/profile_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider()..loadProfile(),
      child: const _ProfileBody(),
    );
  }
}

class _ProfileBody extends StatefulWidget {
  const _ProfileBody();

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  bool _loggingOut = false;
  bool _pickingAvatar = false;
  bool _uploadingAvatar = false;

  Future<void> _pickAndUploadAvatar() async {
    if (_pickingAvatar || _uploadingAvatar) return;
    _pickingAvatar = true;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 88,
      );
      if (picked == null) return;
      if (!mounted) return;

      setState(() => _uploadingAvatar = true);
      final file = File(picked.path);
      await ApiService.instance.uploadAvatar(file: file);
      if (!mounted) return;
      await context.read<ProfileProvider>().loadProfile();
      if (!mounted) return;
      AppSnackBar.showSuccess(context, message: 'Фотография профиля обновлена');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        message: friendlyErrorMessage(
          e,
          fallback: 'Не удалось загрузить фотографию',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _pickingAvatar = false;
          _uploadingAvatar = false;
        });
      }
    }
  }

  String _roleLabel(String? role) {
    switch (role?.trim().toLowerCase()) {
      case 'carrier':
        return 'Специалист';
      case 'client':
        return 'Клиент';
      case '':
      case null:
        return 'Пользователь';
      default:
        return role!.trim();
    }
  }

  Future<void> _logout() async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Выйти из аккаунта?',
      message: 'Придётся войти заново по номеру телефона и паролю.',
      confirmLabel: 'Выйти',
      cancelLabel: 'Остаться',
      danger: true,
      icon: Icons.logout_rounded,
    );

    // Токены очищаются только после подтверждения пользователя.
    if (!confirmed || !mounted) return;

    setState(() => _loggingOut = true);
    await const LogoutService().logout();

    if (!mounted) return;
    setState(() => _loggingOut = false);
    context.go('/select_role');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileProvider>();
    final profile = state.profile;

    final name = (profile?.firstName ?? '').trim().isNotEmpty
        ? profile!.firstName.trim()
        : (state.loading ? 'Загружаем…' : 'Профиль');

    final phone = state.loading && profile == null
        ? '—'
        : formatKgPhone(profile?.phoneNumber);

    final horizontal = AppResponsive.horizontalPadding(context);
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          backgroundColor: AppColors.surface,
          color: AppColors.primary,
          onRefresh: () => context.read<ProfileProvider>().loadProfile(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              horizontal,
              AppSpacing.xs,
              horizontal,
              AppSpacing.xl + safeBottom,
            ),
            child: AppContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Профиль',
                    style: AppResponsive.useCompactTitle(context)
                        ? AppTypography.screenTitleCompact
                        : AppTypography.screenTitle,
                  ),
                  AppSpacing.gapMd,
                  _ProfileHeaderCard(
                    name: name,
                    phone: phone,
                    city: profile?.city,
                    role: _roleLabel(profile?.role),
                    avatarUrl: profile?.avatar,
                    uploadingAvatar: _uploadingAvatar,
                    onAvatarTap: _pickAndUploadAvatar,
                    onEdit: () => context.push('/profile/account'),
                  ),
                  if (state.error != null) ...[
                    AppSpacing.gapMd,
                    AppErrorState(
                      error: state.error,
                      title: 'Не удалось загрузить профиль',
                      compact: true,
                      onRetry: () =>
                          context.read<ProfileProvider>().loadProfile(),
                    ),
                  ],
                  AppSpacing.gapLg,

                  AppTileGroup(
                    title: 'Аккаунт',
                    children: [
                      AppListTile(
                        title: 'Личные данные',
                        subtitle: 'Имя, город, фотография',
                        iconAsset: AppIcons.human,
                        onTap: () => context.push('/profile/account'),
                      ),
                      AppListTile(
                        title: 'История заказов и оплат',
                        subtitle: 'Подтверждённые платежи через Finik',
                        iconAsset: AppIcons.clock,
                        onTap: () => context.go('/history'),
                      ),
                    ],
                  ),
                  AppSpacing.gapMd,

                  AppTileGroup(
                    title: 'Настройки',
                    children: [
                      AppListTile(
                        title: 'Уведомления',
                        subtitle: 'Push-сообщения о статусе заказов',
                        iconAsset: AppIcons.notification,
                        onTap: () => context.push('/profile/notifications'),
                      ),
                    ],
                  ),
                  AppSpacing.gapMd,

                  AppTileGroup(
                    title: 'Поддержка',
                    children: [
                      AppListTile(
                        title: 'Служба поддержки',
                        subtitle: 'Задать вопрос и получить помощь',
                        iconAsset: AppIcons.phone,
                        onTap: () => context.push('/profile/support'),
                      ),
                      AppListTile(
                        title: 'Политика конфиденциальности',
                        icon: Icons.shield_outlined,
                        onTap: () => context.push('/privacy-policy'),
                      ),
                    ],
                  ),
                  AppSpacing.gapXl,

                  AppSecondaryButton(
                    label: 'Выйти из аккаунта',
                    icon: Icons.logout_rounded,
                    danger: true,
                    loading: _loggingOut,
                    onPressed: _logout,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.name,
    required this.phone,
    required this.role,
    required this.city,
    required this.avatarUrl,
    required this.uploadingAvatar,
    required this.onAvatarTap,
    required this.onEdit,
  });

  final String name;
  final String phone;
  final String role;
  final String? city;
  final String? avatarUrl;
  final bool uploadingAvatar;
  final VoidCallback onAvatarTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasCity = city != null && city!.trim().isNotEmpty;

    return AppCard(
      onTap: onEdit,
      semanticLabel: 'Профиль: $name, $phone, $role',
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                AppAvatar(url: avatarUrl, name: name, size: 58),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: uploadingAvatar
                          ? const SizedBox(
                              width: 11,
                              height: 11,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(height: 2),
                Text(phone, style: AppTypography.caption),
                AppSpacing.gapXs,
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    AppStatusBadge(
                      label: role,
                      tone: AppBadgeTone.primary,
                      icon: Icons.badge_outlined,
                      dense: true,
                    ),
                    if (hasCity)
                      AppStatusBadge(
                        label: city!.trim(),
                        icon: Icons.location_city_outlined,
                        dense: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.hGapXxs,
          const Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
