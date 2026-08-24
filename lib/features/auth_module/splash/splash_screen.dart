import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../register/data/models/register_request_model.dart';
import '../register/provider/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );

    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );

    _logoOpacity = CurvedAnimation(
      parent: _logoCtrl,
      curve: Curves.easeOutCubic,
    );
    _textOpacity = CurvedAnimation(
      parent: _textCtrl,
      curve: Curves.easeOutCubic,
    );

    _logoCtrl.forward();

    Future.delayed(
      const Duration(milliseconds: 1050),
      () => _textCtrl.forward(),
    );

    _navTimer = Timer(const Duration(milliseconds: 2900), _navigateNext);
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = await auth.restoreSession();
    final carrierPending = prefs.getBool('carrier_pending') ?? false;
    final userRole = auth.role == UserRole.carrier
        ? 'carrier'
        : prefs.getString('user_role');

    if (!mounted) return;

    if (isLoggedIn) {
      final privacyAccepted = prefs.getBool('privacy_accepted') ?? false;
      if (!privacyAccepted) {
        context.go('/privacy-policy');
        return;
      }

      if (userRole == 'carrier') {
        context.go('/home-carrier');
      } else {
        context.go('/home');
      }
    } else if (carrierPending) {
      context.go('/selfie-waiting');
    } else {
      context.go('/second_splash');
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoOpacity,
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: Image.asset(
                      'assets/images/safa.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _textOpacity,
                  child: const Text(
                    'Safa',
                    style: TextStyle(
                      fontFamily: 'SFProText',
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                      color: Colors.black,
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _textOpacity,
                  child: const Text(
                    'Кыргызский сервис\nнового поколения ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SFProText',
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: FadeTransition(
              opacity: _textOpacity,
              child: Image.asset(
                'assets/images/img_bottom_splash.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
