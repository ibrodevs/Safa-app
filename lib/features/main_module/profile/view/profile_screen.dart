import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/design/app_design.dart';
import '../../../../core/utils/kg_phone_format.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/app_widgets.dart';
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
        return 'Пользователь';
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

  void _showSoon() {
    AppSnackBar.showSoon(context);
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
              parent: BouncingScrollPhysics(),
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
                        title: 'История пополнений и трат',
                        iconAsset: AppIcons.clock,
                        onTap: _showSoon,
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
    required this.onEdit,
  });

  final String name;
  final String phone;
  final String role;
  final String? city;
  final String? avatarUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final hasCity = city != null && city!.trim().isNotEmpty;

    return AppCard(
      onTap: onEdit,
      semanticLabel: 'Профиль: $name, $phone, $role',
      child: Row(
        children: [
          AppAvatar(url: avatarUrl, name: name, size: 56),
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
