import 'package:dogo/core/utils/app_colors.dart';
import 'package:dogo/features/main_module/profile/provider/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  bool _leavingLine = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      PushService.instance.registerOnServerOnce(kind: 'carrier');
    });
  }

  Future<void> _leaveLine() async {
    if (_leavingLine) return;

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

    setState(() => _leavingLine = true);

    // Переход создаёт новый CarrierHomeScreen. Старый экран уничтожается,
    // вместе с ним останавливается таймер поиска ближайших заказов.
    context.go('/home-carrier?line=off');
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
                const SizedBox(height: 260),
                const Center(
                  child: Text(
                    'Пока нет активных\nзаказов',
                    style: TextStyle(
                      fontSize: 21,
                      fontFamily: 'SFProDisplay',
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _leavingLine ? null : _leaveLine,
                    icon: _leavingLine
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.power_settings_new_rounded),
                    label: Text(
                      _leavingLine ? 'Выходим…' : 'Выйти с линии',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
