import 'package:dogo/features/auth_module/register/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/styles.dart';
import '../register/data/models/register_request_model.dart';
import '../register/view/components/register_dots_indicator.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key, this.onTapClient, this.onTapCarrier});

  final VoidCallback? onTapClient;
  final VoidCallback? onTapCarrier;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const _TopPattern(),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Header(),
                        const SizedBox(height: 56),
                        _RoleCard(
                          imageAsset: 'assets/images/img_client.jpg',
                          title: 'Я являюсь клиентом',
                          subtitle:
                              'Узнайте размер и вес посылки для расчета прайса',
                          onTap:
                              onTapClient ??
                              () {
                                context.read<AuthProvider>().setRole(
                                  UserRole.client,
                                );
                                context.push('/register-client');
                              },
                        ),
                        const SizedBox(height: 20),
                        _RoleCard(
                          imageAsset: 'assets/images/img_spec.jpg',
                          title: 'Я являюсь специалистом',
                          subtitle:
                              'Узнайте размер и вес посылки для расчета прайса',
                          onTap:
                              onTapCarrier ??
                              () {
                                context.read<AuthProvider>().setRole(
                                  UserRole.carrier,
                                );
                                context.push('/register-carrier');
                              },
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton(
                            onPressed: () => context.push('/login'),
                            child: const Text(
                              'Уже есть аккаунт? Войти',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE67E22),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding + 20,
            child: const Center(
              child: Hero(
                tag: 'register_dots',
                child: RegisterDotsIndicator(activeIndex: 0),
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Кыргызский сервис\nнового поколения —',
          style: AppTextStyles.titleBlackStyle,
        ),
        Text(
          'всё, что нужно,\nв одном приложении',
          style: AppTextStyles.titleGreyStyle,
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

  static const double _avatarBoxSize = 110.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 24, 10, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE9EDF2), width: 1),
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
              const SizedBox(width: 12),
              const Expanded(child: _RoleTexts()),
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
        Text(card.title, style: AppTextStyles.cardTitleStyle),
        const SizedBox(height: 8),
        Text(card.subtitle, style: AppTextStyles.cardSubtitleStyle),
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
        width: 130,
        fit: BoxFit.cover,
      ),
    );
  }
}
