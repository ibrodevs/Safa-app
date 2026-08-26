import 'package:dogo/core/utils/app_colors.dart';
import 'package:dogo/features/main_module/profile/provider/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../../data/notifications/service/push_service.dart';
import '../widgets/carrier_empty_state.dart';

class EmptyOrdersScreen extends StatelessWidget {
  const EmptyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider()..loadProfile(),
      child: const _EmptyOrdersBody(),
    );
  }
}

class _EmptyOrdersBody extends StatefulWidget {
  const _EmptyOrdersBody();

  @override
  State<_EmptyOrdersBody> createState() => _EmptyOrdersBodyState();
}

class _EmptyOrdersBodyState extends State<_EmptyOrdersBody> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      PushService.instance.registerOnServerOnce(kind: 'carrier');
    });
  }

  Future<void> _leaveLine() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Выйти с линии?'),
            content: const Text(
              'Вы перестанете искать новые заказы. В аккаунте вы останетесь.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(
                  'Выйти с линии',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    // Каждый выход получает новый reset token. Роутер использует URI как ключ
    // CarrierHomeScreen, поэтому старый экран гарантированно уничтожается вместе
    // с таймером поиска заказов и создаётся чистый экран с кнопкой «На линию».
    final resetToken = DateTime.now().microsecondsSinceEpoch;
    context.go('/home-carrier?line=off&reset=$resetToken');
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
          child: CarrierEmptyState(
            greeting: greeting,
            avatarUrl: avatarUrl,
            onLeaveLine: _leaveLine,
          ),
        ),
      ),
    );
  }
}
