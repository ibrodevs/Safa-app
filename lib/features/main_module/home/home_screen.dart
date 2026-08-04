import 'package:dogo/core/design/app_design.dart';
import 'package:dogo/core/widgets/app_widgets.dart';
import 'package:dogo/features/main_module/profile/provider/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/notifications/service/push_service.dart';
import '../map/provider/active_shipment_provider.dart';
import '../services/service_config.dart';
import 'components/active_order_banner.dart';
import 'components/home_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider()..loadProfile(),
      child: const _HomeBody(),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody();

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      PushService.instance.registerOnServerOnce(kind: 'client');
      if (mounted) context.read<ActiveShipmentProvider>().load();
    });
  }

  String _greeting(String name) {
    final hour = DateTime.now().hour;
    final String part;
    if (hour < 6) {
      part = 'Доброй ночи';
    } else if (hour < 12) {
      part = 'Доброе утро';
    } else if (hour < 18) {
      part = 'Добрый день';
    } else {
      part = 'Добрый вечер';
    }
    return '$part, $name';
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<ProfileProvider>().loadProfile(),
      context.read<ActiveShipmentProvider>().load(),
    ]);
  }

  void _openService(ServiceConfig config) {
    if (config.type == ServiceConfig.amanat.type) {
      context.push('/amanat');
      return;
    }
    context.go('/map?service=${config.type}');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileProvider>();
    final profile = state.profile;

    final firstName = profile?.firstName.trim() ?? '';
    final name = firstName.isNotEmpty ? firstName : 'друг';

    final activeShipment = context.watch<ActiveShipmentProvider>().active;
    final horizontal = AppResponsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          strokeWidth: 2.4,
          displacement: 32,
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              horizontal,
              AppSpacing.md,
              horizontal,
              AppSpacing.xl,
            ),
            child: AppContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeHeader(
                    greeting: _greeting(name),
                    prompt: 'Куда отправим сегодня?',
                    avatarUrl: profile?.avatar,
                    name: firstName.isEmpty ? null : firstName,
                    onNotifications: () =>
                        context.push('/profile/notifications'),
                    onProfile: () => context.go('/profile'),
                  ),
                  if (activeShipment != null) ...[
                    AppSpacing.gapLg,
                    ActiveOrderBanner(
                      shipment: activeShipment,
                      onTap: () => context.go('/map'),
                    ),
                  ],
                  AppSpacing.gapXl,
                  const AppSectionHeader(
                    title: 'Что нужно сделать?',
                    subtitle: 'Выберите сервис — маршрут соберём вместе',
                  ),
                  AppSpacing.gapSm,
                  for (final config in ServiceConfig.all) ...[
                    AppServiceCard(
                      title: config.title,
                      description: config.shortDescription,
                      icon: config.icon,
                      accent: config.accent,
                      accentSoft: config.accentSoft,
                      imageAsset: config.imageAsset,
                      onTap: () => _openService(config),
                    ),
                    if (config != ServiceConfig.all.last) AppSpacing.gapSm,
                  ],
                  AppSpacing.gapXl,
                  AppSectionHeader(
                    title: 'Мои заказы',
                    subtitle: 'История и статусы всех обращений',
                    actionLabel: 'Открыть',
                    onAction: () => context.go('/history'),
                  ),
                  AppSpacing.gapSm,
                  AppCard(
                    onTap: () => context.go('/history'),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: AppRadius.allXs,
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppSpacing.hGapSm,
                        Expanded(
                          child: Text(
                            'Посмотреть все заказы и их статусы',
                            style: AppTypography.body,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                  if (state.error != null) ...[
                    AppSpacing.gapMd,
                    AppFormError(message: state.error),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
