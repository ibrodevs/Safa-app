import 'package:dogo/core/utils/app_colors.dart';
import 'package:dogo/features/main_module/profile/provider/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../data/notifications/service/push_service.dart';
import '../widgets/header_empty_row.dart';

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
                HeaderEmptyRow(avatarUrl: avatarUrl, title: greeting),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
