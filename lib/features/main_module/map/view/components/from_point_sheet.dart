import 'package:dogo/features/main_module/map/view/widgets/sheet_back_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:latlong2/latlong.dart';

import '../../data/model/delivery_point_model.dart';
import 'map_picker_screen.dart';

class FromPointSheet extends StatelessWidget {
  const FromPointSheet({
    super.key,
    required this.mainTitle,
    this.bazarTitle,
    required this.lat,
    required this.lon,
    required this.subtitle,
  });

  final String mainTitle;
  final String? bazarTitle;

  final double lat;
  final double lon;
  final String subtitle;

  static const _accent = Color(0xFFFF8A00);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Container(color: const Color(0x33000000)),
          ),
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: double.infinity,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: SafeArea(
                    top: false,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
                      child: _FromPointContent(
                        mainTitle: mainTitle,
                        bazarTitle: bazarTitle,
                        lat: lat,
                        lon: lon,
                        subtitle: subtitle,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  right: 16,
                  top: 12,
                  child: SheetBackPill(
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FromPointContent extends StatefulWidget {
  const _FromPointContent({
    required this.mainTitle,
    required this.bazarTitle,
    required this.lat,
    required this.lon,
    required this.subtitle,
  });

  final String mainTitle;
  final String? bazarTitle;
  final double lat;
  final double lon;
  final String subtitle;

  @override
  State<_FromPointContent> createState() => _FromPointContentState();
}

class _FromPointContentState extends State<_FromPointContent> {
  final TextEditingController _bazarCtrl = TextEditingController();
  final TextEditingController _containerCtrl = TextEditingController();
  final TextEditingController _passageCtrl = TextEditingController();
  DeliveryPoint? _pickedOnMap;

  @override
  void dispose() {
    _bazarCtrl.dispose();
    _containerCtrl.dispose();
    _passageCtrl.dispose();
    super.dispose();
  }

  String _subtitleFrom(String container, String passage) {
    final c = container.trim();
    final p = passage.trim();
    if (c.isEmpty && p.isEmpty) return '';
    if (c.isNotEmpty && p.isNotEmpty) return 'Контейнер: $c • Проход: $p';
    if (c.isNotEmpty) return 'Контейнер: $c';
    return 'Проход: $p';
  }

  void _submit() {
    if (_pickedOnMap != null) {
      final p = _pickedOnMap!;
      Navigator.of(context).pop(
        DeliveryPoint(
          title: p.title,
          subtitle: p.subtitle,
          lat: p.lat,
          lon: p.lon,
          bazar: '',
          container: '',
          passage: '',
          q: '',
        ),
      );
      return;
    }

    final bazar = _bazarCtrl.text.trim();
    final container = _containerCtrl.text.trim();
    final passage = _passageCtrl.text.trim();

    final point = DeliveryPoint(
      title: bazar.isNotEmpty ? bazar : widget.mainTitle,
      subtitle: _subtitleFrom(container, passage),
      lat: null,
      lon: null,
      bazar: bazar,
      container: container,
      passage: passage,
      q: '',
    );

    Navigator.of(context).pop(point);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Точка отправки',
            style: TextStyle(
              fontSize: 28,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.mainTitle,
            style: const TextStyle(
              fontSize: 18,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.bazarTitle ?? widget.subtitle,
            style: const TextStyle(
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: FromPointSheet._greyText,
            ),
          ),
          const SizedBox(height: 24),

          _MainInput(controller: _bazarCtrl, hint: 'Откуда отправка'),

          const SizedBox(height: 22),
          const Divider(height: 1, color: FromPointSheet._tileBorder),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _ChipField(
                  hint: 'Контейнер',
                  controller: _containerCtrl,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChipField(hint: 'Проход', controller: _passageCtrl),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final p = await Navigator.of(context).push<DeliveryPoint>(
                  MaterialPageRoute(
                    builder: (_) => MapPickerScreen(
                      initial: LatLng(widget.lat, widget.lon),
                      title: 'Точка отправки',
                    ),
                  ),
                );
                if (!mounted || p == null) return;

                setState(() {
                  _pickedOnMap = p;
                  _bazarCtrl.clear();
                  _containerCtrl.clear();
                  _passageCtrl.clear();
                });
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: FromPointSheet._tileBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Карта'),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: FromPointSheet._accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Далее'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainInput extends StatelessWidget {
  const _MainInput({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FromPointSheet._tileBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/ic_box.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              FromPointSheet._accent,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: FromPointSheet._greyText,
                ),
              ),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              cursorColor: Colors.black,
              textInputAction: TextInputAction.next,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipField extends StatelessWidget {
  const _ChipField({required this.hint, required this.controller});

  final String hint;
  final TextEditingController controller;

  static const _accent = Color(0xFFFF8A00);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _greyText = Color(0xFF9FA4AD);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _tileBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/ic_box.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(_accent, BlendMode.srcIn),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _greyText,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              cursorColor: Colors.black,
              textInputAction: TextInputAction.next,
            ),
          ),
        ],
      ),
    );
  }
}
