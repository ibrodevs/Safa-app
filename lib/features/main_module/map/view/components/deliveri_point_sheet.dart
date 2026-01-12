import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:latlong2/latlong.dart';

import '../../data/model/delivery_point_model.dart';
import '../widgets/sheet_back_pill.dart';
import 'map_picker_screen.dart';

class DeliveryPointSheet extends StatelessWidget {
  const DeliveryPointSheet({
    super.key,
    required this.mainTitle,
    this.bazarTitle,
    required this.lat,
    required this.lon,
  });

  final String mainTitle;
  final String? bazarTitle;
  final double lat;
  final double lon;

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
                      child: _DeliveryPointContent(
                        mainTitle: mainTitle,
                        bazarTitle: bazarTitle,
                        lat: lat,
                        lon: lon,
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

class _DeliveryPointContent extends StatefulWidget {
  const _DeliveryPointContent({
    required this.mainTitle,
    required this.bazarTitle,
    required this.lat,
    required this.lon,
  });

  final String mainTitle;
  final String? bazarTitle;
  final double lat;
  final double lon;

  @override
  State<_DeliveryPointContent> createState() => _DeliveryPointContentState();
}

class _DeliveryPointContentState extends State<_DeliveryPointContent> {
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
            'Точка доставки',
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
            widget.bazarTitle ?? '',
            style: const TextStyle(
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: DeliveryPointSheet._greyText,
            ),
          ),
          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _MainInput(
                  controller: _bazarCtrl,
                  hint: 'Откуда отправка',
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () async {
                  FocusScope.of(context).unfocus();

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
                    // если хочешь показать выбранное место в поле:
                    _bazarCtrl.text = p.title;
                    _containerCtrl.clear();
                    _passageCtrl.clear();
                  });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: DeliveryPointSheet._accent,
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.near_me_rounded, size: 20),
                label: const Text('Карта'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: DeliveryPointSheet._tileBorder),
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
          const SizedBox(height: 28),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: DeliveryPointSheet._accent,
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
        border: Border.all(color: DeliveryPointSheet._tileBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/ic_box.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              DeliveryPointSheet._accent,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: DeliveryPointSheet._greyText,
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
