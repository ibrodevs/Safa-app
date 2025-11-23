// lib/features/auth_module/splash/second_splash_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class SecondSplashScreen extends StatefulWidget {
  const SecondSplashScreen({super.key});

  @override
  State<SecondSplashScreen> createState() => _SecondSplashScreenState();
}

class _SecondSplashScreenState extends State<SecondSplashScreen>
    with TickerProviderStateMixin {
  static const _titleGrey = Color(0xFFB5BCC5);
  static const _orange = Color(0xFFFF8A00);
  static const _orangeSoft = Color(0xFFFFE6D2);
  static const _purple = Color(0xFF5A46FF);
  static const _purpleSoft = Color(0xFFE4DDFF);

  late final AnimationController _heroCtrl;
  late final AnimationController _contentCtrl;
  late final Animation<double> _heroOpacity;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _heroOffset;

  Timer? _navTimer;

  static const _titleBlackStyle = TextStyle(
    fontSize: 24,
    height: 1.1,
    fontFamily: 'SFProText',
    fontWeight: FontWeight.w700,
    color: Colors.black,
  );

  static const _titleGreyStyle = TextStyle(
    fontSize: 24,
    height: 1.1,
    fontFamily: 'SFProText',
    fontWeight: FontWeight.w600,
    color: _titleGrey,
  );

  static const _chipTextStyle = TextStyle(
    fontSize: 13,
    height: 1.1,
    fontFamily: 'SFProText',
    fontWeight: FontWeight.w600,
  );

  @override
  void initState() {
    super.initState();

    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2300),
    );

    _heroOpacity = CurvedAnimation(
      parent: _heroCtrl,
      curve: Curves.easeOutCubic,
    );
    _contentOpacity = CurvedAnimation(
      parent: _contentCtrl,
      curve: Curves.easeOutCubic,
    );

    _heroOffset = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).chain(
      CurveTween(curve: Curves.easeOutCubic),
    ).animate(_heroCtrl);

    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      _heroCtrl.forward();
    });

    Future.delayed(const Duration(milliseconds: 1050), () {
      if (!mounted) return;
      _contentCtrl.forward();
    });

    _navTimer = Timer(const Duration(milliseconds: 2900), () {
      if (mounted) context.go('/select_role');
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _heroCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: FadeTransition(
              opacity: _contentOpacity,
              child: Image.asset(
                'assets/images/img_bottom_splash.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
            ),
          ),

          Positioned(
            right: 0,
            top: 51,
            bottom: -51,
            left: 0,
            child: FadeTransition(
              opacity: _heroOpacity,
              child: SlideTransition(
                position: _heroOffset,
                child: Image.asset(
                  'assets/images/img_route.png',
                  height: 520,
                ),
              ),
            ),
          ),

          Positioned(
            right: 70,
            top: 470,
            child: FadeTransition(
              opacity: _heroOpacity,
              child: SlideTransition(
                position: _heroOffset,
                child: Image.asset(
                  'assets/images/img_arrow_nav.png',
                  width: 42,
                  height: 42,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: FadeTransition(
                opacity: _contentOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    const Text(
                      'Кыргызский сервис\nнового поколения —',
                      style: _titleBlackStyle,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'всё, что нужно,\nв одном приложении',
                      style: _titleGreyStyle,
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: const [
                        _CategoryChip(
                          title: 'Доставка грузов',
                          background: _orangeSoft,
                          borderColor: Colors.transparent,
                          textColor: _orange,
                          iconColor: _orange,
                        ),
                        _CategoryChip(
                          title: 'Такси',
                          background: Colors.white,
                          borderColor: _purple,
                          textColor: _purple,
                          iconColor: _purple,
                        ),
                        _CategoryChip(
                          title: 'Благотворительность',
                          background: _orange,
                          borderColor: Colors.transparent,
                          textColor: Colors.white,
                          iconColor: Colors.white,
                        ),
                        _CategoryChip(
                          title: 'Путешествия',
                          background: _orangeSoft,
                          borderColor: Colors.transparent,
                          textColor: _orange,
                          iconColor: _orange,
                        ),
                        _CategoryChip(
                          title: 'Покупки',
                          background: _purpleSoft,
                          borderColor: Colors.transparent,
                          textColor: _purple,
                          iconColor: _purple,
                        ),
                        _CategoryChip(
                          title: 'Услуги',
                          background: Colors.white,
                          borderColor: _purple,
                          textColor: _purple,
                          iconColor: _purple,
                        ),
                        _CategoryChip(
                          title: 'Сервисы',
                          background: _orange,
                          borderColor: Colors.transparent,
                          textColor: Colors.white,
                          iconColor: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.title,
    required this.background,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
  });

  final String title;
  final Color background;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      constraints: const BoxConstraints(minWidth: 85),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/ic_box.svg',
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              iconColor,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: _SecondSplashScreenState._chipTextStyle
                .copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
