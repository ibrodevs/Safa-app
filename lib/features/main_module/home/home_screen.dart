import 'package:dogo/core/utils/app_colors.dart';
import 'package:dogo/features/main_module/profile/provider/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../data/notifications/service/push_service.dart';
import 'components/big_card_widget.dart';
import 'components/header_widget.dart';
import 'components/small_card_widget.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ProfileProvider>();
    final profile = state.profile;
    String name = 'друг';
    if (profile != null) {
      final topFirst = profile.firstName.trim();
      if (topFirst.isNotEmpty) {
        name = topFirst;
      }
    }
    final greeting = 'Добрый день, $name';
    final avatarUrl = profile?.avatar;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          backgroundColor: AppColors.white,
          strokeWidth: 2.4,
          displacement: 32,
          onRefresh: () => context.read<ProfileProvider>().loadProfile(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderRow(avatarUrl: avatarUrl, title: greeting),
                const SizedBox(height: 24),
                const Text(
                  'Основное',
                  style: TextStyle(
                    fontSize: 21,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Отслеживайте и узнавайте адреса\n'
                  'актуальных складов для доставки товаров',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: AppColors.greyText,
                  ),
                ),
                const SizedBox(height: 18),
                BigFeatureCard(
                  title: 'Доставка грузов',
                  subtitle: 'Узнайте размер\nи вес посылки для\nрасчета прайса',
                  tagText: 'Скоро',
                  imageAsset: 'assets/images/boxes2.png',
                  onTap: () => context.go('/map'),
                ),
                const SizedBox(height: 18),
                BigFeatureCard(
                  title: 'Такси',
                  subtitle: 'Узнайте размер\nи вес посылки для\nрасчета прайса',
                  tagText: 'Скоро',
                  imageAsset: 'assets/images/img_home_car2.png',
                  onTap: () => context.go('/map'),
                ),
                const SizedBox(height: 18),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SmallFeatureCard(
                          title: 'Аманат',
                          subtitle:
                              'Узнайте размер и вес посылки для расчета прайса',
                          tagText: 'Скоро',
                          imageAsset: 'assets/images/img_home_amanat.png',
                          imageHeight: 55,
                          imageScale: 0.9,
                          imagePadding: 18,
                          imagePadding2: 8,
                          onTap: () => context.go('/map'),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: SmallFeatureCard(
                          title: 'Специалисты',
                          subtitle:
                              'Узнайте размер и вес посылки для расчета прайса',
                          tagText: 'Скоро',
                          imageAsset: 'assets/images/img_home_specialists.png',
                          onTap: () => context.go('/map'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.error!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
