// lib/features/main_module/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _accent = Color(0xFFFF8A00);
  static const _greyText = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeaderRow(),
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
                  color: _greyText,
                ),
              ),
              const SizedBox(height: 18),

              _BigFeatureCard(
                title: 'Доставка грузов',
                subtitle: 'Узнайте размер\nи вес посылки для\nрасчета прайса',
                tagText: 'Внутри Дордоя',
                imageAsset: 'assets/images/img_home_boxes.png',
                onTap: () {},
              ),
              const SizedBox(height: 18),

              _BigFeatureCard(
                title: 'Такси',
                subtitle: 'Узнайте размер\nи вес посылки для\nрасчета прайса',
                tagText: 'Внутри Дордоя',
                imageAsset: 'assets/images/img_home_car.png',
                onTap: () => context.go('/map'),
              ),
              const SizedBox(height: 18),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _SmallFeatureCard(
                        title: 'Аманат',
                        subtitle: 'Узнайте размер\nи вес посылки для\nрасчета прайса',
                        tagText: 'По всему КР',
                        imageAsset: 'assets/images/img_home_amanat.png',
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _SmallFeatureCard(
                        title: 'Специалисты',
                        subtitle: 'Узнайте размер\nи вес посылки для\nрасчета прайса',
                        tagText: 'Внутри Дордоя',
                        imageAsset: 'assets/images/img_home_specialists.png',
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            'https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?w=256',
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Добрый день, Арслан',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 24,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class _BigFeatureCard extends StatelessWidget {
  const _BigFeatureCard({
    required this.title,
    required this.subtitle,
    required this.tagText,
    required this.imageAsset,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String tagText;
  final String imageAsset;
  final VoidCallback onTap;

  static const double _radius = 20;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: HomeScreen._tileBorder, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                          color: HomeScreen._greyText,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const SizedBox(height: 2),
                      _TagChip(text: tagText),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 140,
                height: 120,
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _SmallFeatureCard extends StatelessWidget {
  const _SmallFeatureCard({
    required this.title,
    required this.subtitle,
    required this.tagText,
    required this.imageAsset,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String tagText;
  final String imageAsset;
  final VoidCallback onTap;

  static const double _radius = 20;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: HomeScreen._tileBorder, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  height: 70,
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                  color: HomeScreen._greyText,
                ),
              ),
              const SizedBox(height: 16),
              _TagChip(text: tagText, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.text,
    this.compact = false,
  });

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 32.0 : 36.0;
    final horizontalPadding = compact ? 4.0 : 4.0;

    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE6D2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/ic_box.svg',
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  HomeScreen._accent,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 11 : 13,
                height: 1.1,
                fontWeight: FontWeight.w700,
                color: HomeScreen._accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
