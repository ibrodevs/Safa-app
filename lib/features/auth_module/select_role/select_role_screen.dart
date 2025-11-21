import 'package:dogo/features/auth_module/register/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../register/data/models/register_request_model.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({
    super.key,
    this.onTapClient,
    this.onTapCarrier,
  });

  final VoidCallback? onTapClient;
  final VoidCallback? onTapCarrier;

  static const _sidePadding = 24.0;

  static const _bgColor = Color(0xFFF5F3F2);
  static const _orange = Color(0xFFFF8A00);
  static const _greyText = Color(0xFF9FA4AD);

  static const _titleBlackStyle = TextStyle(
    fontFamily: 'SFProText',
    fontWeight: FontWeight.w700,
    fontSize: 24,
    height: 1.1,
    color: Colors.black,
  );

  static const _titleGreyStyle = TextStyle(
    fontFamily: 'SFProText',
    fontWeight: FontWeight.w600,
    fontSize: 24,
    height: 1.1,
    color: Color(0xFFB5BCC5),
  );

  static const _cardTitleStyle = TextStyle(
    fontFamily: 'SFProText',
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.2,
    color: Colors.black,
  );

  static const _cardSubtitleStyle = TextStyle(
    fontFamily: 'SFProText',
    fontWeight: FontWeight.w500,
    fontSize: 13,
    height: 1.25,
    color: _greyText,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          const _TopPattern(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      _sidePadding,
                      40,
                      _sidePadding,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Header(),
                        const SizedBox(height: 56),
                        _RoleCard(
                          imageAsset: 'assets/images/img_role_client.png',
                          title: 'Я являюсь клиентом',
                          subtitle:
                          'Узнайте размер и вес посылки\nдля расчета прайса',
                          onTap: onTapClient ??
                                  () {
                                context.read<AuthProvider>().setRole(UserRole.client);
                                context.push('/register');
                              },
                        ),
                        const SizedBox(height: 20),
                        _RoleCard(
                          imageAsset: 'assets/images/img_role_specialist.png',
                          title: 'Я являюсь специалистом',
                          subtitle:
                          'Узнайте размер и вес посылки\nдля расчета прайса',
                          onTap: onTapCarrier ??
                                  () {
                                context.read<AuthProvider>().setRole(UserRole.carrier);
                                context.push('/register/id');
                              },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const _PagerIndicator(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Кыргызский сервис\nнового поколения —',
          style: RoleSelectScreen._titleBlackStyle,
        ),
        SizedBox(height: 12),
        Text(
          'всё, что нужно,\nв одном приложении',
          style: RoleSelectScreen._titleGreyStyle,
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String imageAsset;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  static const double _avatarBoxSize = 120.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFE9EDF2),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: _avatarBoxSize,
                height: _avatarBoxSize,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                ),
              ),
              const SizedBox(width: 24),
              const Expanded(
                child: _RoleTexts(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTexts extends StatelessWidget {
  const _RoleTexts();

  @override
  Widget build(BuildContext context) {
    final card = context.findAncestorWidgetOfExactType<_RoleCard>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          card.title,
          style: RoleSelectScreen._cardTitleStyle,
        ),
        const SizedBox(height: 8),
        Text(
          card.subtitle,
          style: RoleSelectScreen._cardSubtitleStyle,
        ),
      ],
    );
  }
}

class _TopPattern extends StatelessWidget {
  const _TopPattern();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      child: Image.asset(
        'assets/images/img_tunduk.png',
        width: 140,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _PagerIndicator extends StatelessWidget {
  const _PagerIndicator();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _Dot(active: true),
            SizedBox(width: 12),
            _Dot(active: false),
            SizedBox(width: 12),
            _Dot(active: false),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: 180,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? RoleSelectScreen._orange : const Color(0xFFD5DAE0),
      ),
    );
  }
}
