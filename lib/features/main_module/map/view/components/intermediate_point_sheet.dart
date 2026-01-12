import 'package:dogo/core/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import '../../data/model/delivery_point_model.dart';
import '../widgets/sheet_back_pill.dart';
import 'map_picker_screen.dart';

class IntermediatePointSheet extends StatefulWidget {
  const IntermediatePointSheet({
    required this.addressLine,
    required this.placeLine,
    required this.lat,
    required this.lon,
    super.key,
  });

  final String addressLine;
  final String placeLine;
  final double lat;
  final double lon;

  @override
  State<IntermediatePointSheet> createState() => _IntermediatePointSheetState();
}

class _IntermediatePointSheetState extends State<IntermediatePointSheet> {
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

    Navigator.of(context).pop(
      DeliveryPoint(
        title: bazar.isNotEmpty ? bazar : widget.addressLine,
        subtitle: _subtitleFrom(container, passage),
        lat: null,
        lon: null,
        bazar: bazar,
        container: container,
        passage: passage,
        q: '',
      ),
    );
  }

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
                  child: Material(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 24, 16 + bottom),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Промежуточная точка',
                                style: TextStyle(
                                  fontSize: 28,
                                  height: 1.1,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.addressLine,
                                style: TextStyle(
                                  fontSize: 20,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.placeLine,
                                style: TextStyle(
                                  fontSize: 17,
                                  height: 1.2,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey,
                                ),
                              ),
                              const SizedBox(height: 24),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.tileBorder,
                                          width: 1,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                            'assets/icons/ic_box.svg',
                                            width: 20,
                                            height: 20,
                                            colorFilter: const ColorFilter.mode(
                                              AppColors.accent,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: TextField(
                                              controller: _bazarCtrl,
                                              decoration: const InputDecoration(
                                                isCollapsed: true, // ✅ чтобы было по центру по высоте
                                                border: InputBorder.none,
                                                hintText: 'Откуда отправка',
                                                hintStyle: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.chev,
                                                ),
                                              ),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.black,
                                              ),
                                              cursorColor: AppColors.black,
                                              textInputAction: TextInputAction.next,
                                            ),
                                          ),
                                        ],
                                      ),
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

                                        // чтобы было понятно, что выбрали
                                        _bazarCtrl.text = p.title;

                                        _containerCtrl.clear();
                                        _passageCtrl.clear();
                                      });
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      foregroundColor: AppColors.accent,
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
                              const SizedBox(height: 22),
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: AppColors.tileBorder,
                              ),
                              const SizedBox(height: 18),

                              Row(
                                children: [
                                  Expanded(
                                    child: _TagField(
                                      hint: 'Контейнер',
                                      controller: _containerCtrl,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _TagField(
                                      hint: 'Проход',
                                      controller: _passageCtrl,
                                    ),
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
                                    elevation: 0,
                                    backgroundColor: AppColors.accent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: const Text('Далее'),
                                ),
                              ),
                            ],
                          ),
                        ),
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

class _TagField extends StatelessWidget {
  const _TagField({required this.hint, required this.controller});

  final String hint;
  final TextEditingController controller;

  static const _accent = Color(0xFFFF8A00);
  static const _tileBorder = Color(0xFFE9EDF2);
  static const _greyText = Color(0xFFC7CFD9);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _tileBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  fontWeight: FontWeight.w700,
                  color: _greyText,
                ),
              ),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
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
