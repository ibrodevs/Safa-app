// lib/features/cargo/select_type/cargo_type_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class CargoTypeScreen extends StatefulWidget {
  const CargoTypeScreen({super.key});

  @override
  State<CargoTypeScreen> createState() => _CargoTypeScreenState();
}

class _CargoTypeScreenState extends State<CargoTypeScreen> {
  static const _accent = Color(0xFFE67E22);
  static const _grey = Color(0xFF9FA4AD);
  static const _tileBorder = Color(0xFFE9EDF2);

  int? _selected;
  int _qty = 5;

  final _types = const [
    ('Мешок', 'Мешки с товары'),
    ('Пакет', 'Пакеты с товарами'),
    ('Коробка', 'Коробки с товарами'),
    ('Товары', 'Хоз товары'),
  ];

  String get _selectedName => _selected == null ? '' : _types[_selected!].$1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.canPop() ? context.pop() : null,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.chevron_left, size: 28, color: Color(0xFFB9C0C8)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Тип груза',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              const _PlaceLine(title: 'Контейнер 74, 8 проход', subtitle: 'Алкан базары'),
              const SizedBox(height: 6),
              const Icon(Icons.arrow_downward_rounded, size: 28, color: Colors.black),
              const SizedBox(height: 6),
              const _PlaceLine(title: 'Контейнер 19, 9 проход', subtitle: 'Кытай базары'),
              const SizedBox(height: 18),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _tile(0)),
                  const SizedBox(width: 18),
                  Expanded(child: _tile(1)),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _tile(2)),
                  const SizedBox(width: 18),
                  Expanded(child: _tile(3)),
                ],
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _selected == null
                    ? const SizedBox.shrink()
                    : Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Выберите количество:',
                        style: TextStyle(
                          fontSize: 21,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Выберите количество ${_selectedName.toLowerCase()}ов',
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: _grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _tileBorder, width: 1),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x11000000), blurRadius: 20, offset: Offset(0, 8)),
                                  BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/ic_box.svg',
                                    width: 36,
                                    height: 36,
                                    colorFilter: const ColorFilter.mode(_accent, BlendMode.srcIn),
                                  ),
                                  const SizedBox(width: 14),
                                  Text(
                                    '$_qty',
                                    style: const TextStyle(
                                      fontSize: 21,
                                      height: 1.0,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _selectedName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.0,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          _roundBtn(icon: Icons.remove, onTap: () => setState(() => _qty = (_qty - 1).clamp(0, 999))),
                          const SizedBox(width: 12),
                          _roundBtn(icon: Icons.add, onTap: () => setState(() => _qty = (_qty + 1).clamp(0, 999))),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 64,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {/* continue */},
                          style: ButtonStyle(
                            backgroundColor: const WidgetStatePropertyAll(_accent),
                            foregroundColor: const WidgetStatePropertyAll(Colors.white),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            elevation: const WidgetStatePropertyAll(0),
                            textStyle: const WidgetStatePropertyAll(
                              TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.0),
                            ),
                          ),
                          child: const Text('Далее'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(int index) {
    final (title, subtitle) = _types[index];
    final selected = _selected == index;

    return _CargoTile(
      iconAsset: 'assets/icons/ic_box.svg',
      title: title,
      subtitle: subtitle,
      selected: selected,
      onTap: () => setState(() {
        _selected = index;
      }),
    );
  }

  Widget _roundBtn({required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      height: 64,
      width: 64,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _tileBorder, width: 1),
            ),
            child: Icon(icon, size: 28, color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class _PlaceLine extends StatelessWidget {
  const _PlaceLine({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            height: 1.15,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 15,
            height: 1.2,
            fontWeight: FontWeight.w600,
            color: Color(0xFF9FA4AD),
          ),
        ),
      ],
    );
  }
}

class _CargoTile extends StatelessWidget {
  const _CargoTile({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    this.selected = false,
    this.onTap,
  });

  final String iconAsset;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  static const _accent = Color(0xFFE67E22);
  static const _tileBorder = Color(0xFFE9EDF2);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _tileBorder, width: 1),
              boxShadow: const [
                BoxShadow(color: Color(0x11000000), blurRadius: 20, offset: Offset(0, 8)),
                BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        iconAsset,
                        width: 36,
                        height: 36,
                        colorFilter: const ColorFilter.mode(_accent, BlendMode.srcIn),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9FA4AD),
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: 16,
                  right: 16,
                  child: selected
                      ? Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                  )
                      : Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDEFF1),
                      shape: BoxShape.circle,
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
