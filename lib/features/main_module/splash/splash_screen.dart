import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

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

    _navTimer = Timer(const Duration(milliseconds: 2900), () {
      if (mounted) context.go('/second_splash');
    });
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
                  child: Image.asset(
                    'assets/images/img_splash.png',
                  ) /*SvgPicture.asset(
                    'assets/icons/ic_logo.svg',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),*/,
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _textOpacity,
                  child: const Text(
                    'DoGo',
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
