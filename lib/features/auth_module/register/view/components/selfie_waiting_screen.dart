import 'dart:async';

import 'package:dogo/features/auth_module/register/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelfieWaitingScreen extends StatefulWidget {
  const SelfieWaitingScreen({super.key});

  static const routePath = '/selfie-waiting';

  @override
  State<SelfieWaitingScreen> createState() => _SelfieWaitingScreenState();
}

class _SelfieWaitingScreenState extends State<SelfieWaitingScreen> {
  static const _accent = Color(0xFFE67E22);
  static const _cancelGrey = Color(0xFFB9C0C8);

  Timer? _timer;
  int? _lastStatus;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStatus();
      _timer = Timer.periodic(
        const Duration(seconds: 15),
            (_) => _checkStatus(),
      );
    });
  }

  Future<void> _checkStatus() async {
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final status = await auth.carrierWait();

    if (!mounted) return;

    if (status == null) {
      final msg = auth.error ?? 'Ошибка при проверке статуса';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      return;
    }

    if (status == _lastStatus) return;
    _lastStatus = status;

    if (status == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('carrier_pending', false);
      await prefs.setString('user_role', 'carrier');

      _timer?.cancel();
      if (!mounted) return;
      context.go('/home-carrier');
    }
    else if (status == 403) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Профиль на проверке'),
        ),
      );
    } else if (status == 404) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Перевозчик не найден'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Неизвестный статус: $status')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final auth = context.read<AuthProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              const Center(
                child: Icon(
                  Icons.access_time_rounded,
                  size: 96,
                  color: _accent,
                ),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Ожидайте подтверждения',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Сатурн—шестая планета по удалённости от '
                      'Солнца и вторая по размерам планета',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.3,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Spacer(flex: 4),
              SizedBox(
                height: 64,
                child: ElevatedButton(
                  onPressed: _checkStatus,
                  style: ButtonStyle(
                    backgroundColor:
                    const WidgetStatePropertyAll(Color(0xFFE67E22)),
                    foregroundColor:
                    const WidgetStatePropertyAll(Colors.white),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    elevation: const WidgetStatePropertyAll(0),
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                  child: const Text('Далее'),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('carrier_pending', false);
                    await prefs.setBool('is_logged_in', false);
                    if (!mounted) return;
                    context.go('/select_role');
                  },
                  child: const Text(
                    'Отменить регистрацию',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                      color: _cancelGrey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
