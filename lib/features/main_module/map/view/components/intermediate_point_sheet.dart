import 'package:dogo/core/utils/app_colors.dart';
import 'package:dogo/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../data/model/delivery_point_model.dart';
import '../../data/model/delivery_refs_models.dart';
import '../../data/repo/delivery_refs_repository.dart';
import '../widgets/ref_suggest_field.dart';
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

  final DeliveryRefsRepository _refs = DeliveryRefsRepository();

  DeliveryPoint? _pickedOnMap;
  BazarRef? _bazar;
  PassageRef? _passage;
  ContainerRef? _container;
  bool _submitting = false;

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

  Future<List<RefSuggestion<BazarRef>>> _fetchBazars(String q) async {
    final list = await _refs.searchBazars(q);
    return list.map((b) => RefSuggestion(label: b.name, value: b)).toList();
  }

  Future<List<RefSuggestion<PassageRef>>> _fetchPassages(String q) async {
    final list = await _refs.searchPassages(query: q, bazarId: _bazar?.id);
    return list
        .map((p) => RefSuggestion(
              label: p.number,
              sublabel: p.bazarName,
              value: p,
            ))
        .toList();
  }

  Future<List<RefSuggestion<ContainerRef>>> _fetchContainers(String q) async {
    final list = await _refs.searchContainers(
      query: q,
      bazarId: _bazar?.id,
      passageId: _passage?.id,
    );
    return list
        .map((c) => RefSuggestion(
              label: 'Контейнер ${c.number}',
              sublabel: '${c.passageNumber} · ${c.bazarName}',
              fillText: c.number,
              value: c,
            ))
        .toList();
  }

  void _onBazarSelected(RefSuggestion<BazarRef> s) {
    setState(() {
      _bazar = s.value;
      _pickedOnMap = null;
      _passage = null;
      _container = null;
      _passageCtrl.clear();
      _containerCtrl.clear();
    });
  }

  void _onPassageSelected(RefSuggestion<PassageRef> s) {
    final p = s.value;
    setState(() {
      _passage = p;
      _pickedOnMap = null;
      _container = null;
      _containerCtrl.clear();
      if (_bazar?.id != p.bazarId) {
        _bazar = BazarRef(id: p.bazarId, name: p.bazarName);
        _bazarCtrl.text = p.bazarName;
      }
    });
  }

  void _onContainerSelected(RefSuggestion<ContainerRef> s) {
    final c = s.value;
    setState(() {
      _container = c;
      _pickedOnMap = null;
      _bazar = BazarRef(id: c.bazarId, name: c.bazarName);
      _bazarCtrl.text = c.bazarName;
      _passage = PassageRef(
        id: c.passageId,
        bazarId: c.bazarId,
        bazarName: c.bazarName,
        number: c.passageNumber,
      );
      _passageCtrl.text = c.passageNumber;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;

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

    var c = _container;

    // Пользователь ввёл номер контейнера руками — ищем его в базе,
    // чтобы точка всегда была из справочника (с координатами).
    if (c == null && _containerCtrl.text.trim().isNotEmpty) {
      setState(() => _submitting = true);
      try {
        final found = await _refs.searchContainers(
          query: _containerCtrl.text.trim(),
          bazarId: _bazar?.id,
          passageId: _passage?.id,
          pageSize: 1,
        );
        if (found.isNotEmpty) c = found.first;
      } catch (_) {
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      if (!mounted) return;
    }

    if (c == null || c.latValue == null || c.lonValue == null) {
      AppSnackBar.showError(
        context,
        message: 'Выберите контейнер из списка или укажите точку на карте',
      );
      return;
    }

    final bazarName =
        _bazarCtrl.text.trim().isNotEmpty ? _bazarCtrl.text.trim() : c.bazarName;

    Navigator.of(context).pop(
      DeliveryPoint(
        title: bazarName.isNotEmpty ? bazarName : widget.addressLine,
        subtitle: _subtitleFrom(c.number, c.passageNumber),
        lat: c.latValue,
        lon: c.lonValue,
        bazar: bazarName,
        container: c.number,
        passage: c.passageNumber,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: RefSuggestField<BazarRef>(
                                      controller: _bazarCtrl,
                                      hint: 'Базар',
                                      fetch: _fetchBazars,
                                      onSelected: _onBazarSelected,
                                      onTextEdited: () {
                                        _bazar = null;
                                        _pickedOnMap = null;
                                      },
                                      height: 56,
                                      radius: 16,
                                      horizontalPadding: 16,
                                      fontSize: 16,
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  SizedBox(
                                    height: 56,
                                    child: Center(
                                      child: TextButton.icon(
                                        onPressed: () async {
                                          FocusScope.of(context).unfocus();

                                          final p = await Navigator.of(context).push<DeliveryPoint>(
                                            MaterialPageRoute(
                                              builder: (_) => MapPickerScreen(
                                                initial: LatLng(widget.lat, widget.lon),
                                                title: 'Промежуточная точка',
                                              ),
                                            ),
                                          );
                                          if (!mounted || p == null) return;

                                          setState(() {
                                            _pickedOnMap = p;
                                            _bazar = null;
                                            _passage = null;
                                            _container = null;

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
                                    ),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: RefSuggestField<ContainerRef>(
                                      controller: _containerCtrl,
                                      hint: 'Контейнер',
                                      fetch: _fetchContainers,
                                      onSelected: _onContainerSelected,
                                      onTextEdited: () => _container = null,
                                      height: 56,
                                      radius: 16,
                                      horizontalPadding: 16,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      hintColor: const Color(0xFFC7CFD9),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: RefSuggestField<PassageRef>(
                                      controller: _passageCtrl,
                                      hint: 'Проход',
                                      fetch: _fetchPassages,
                                      onSelected: _onPassageSelected,
                                      onTextEdited: () => _passage = null,
                                      height: 56,
                                      radius: 16,
                                      horizontalPadding: 16,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      hintColor: const Color(0xFFC7CFD9),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 28),
                              SizedBox(
                                height: 56,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _submitting ? null : _submit,
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
                                  child: Text(_submitting ? 'Проверяем…' : 'Далее'),
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
