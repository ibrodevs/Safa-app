import 'package:dogo/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../data/model/delivery_point_model.dart';
import '../../data/model/delivery_refs_models.dart';
import '../../data/repo/delivery_refs_repository.dart';
import '../widgets/ref_suggest_field.dart';
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
        title: bazarName.isNotEmpty ? bazarName : widget.mainTitle,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RefSuggestField<BazarRef>(
                  controller: _bazarCtrl,
                  hint: 'Куда доставить',
                  fetch: _fetchBazars,
                  onSelected: _onBazarSelected,
                  onTextEdited: () {
                    _bazar = null;
                    _pickedOnMap = null;
                  },
                  height: 52,
                  fillColor: const Color(0xFFF6F7FA),
                  radius: 14,
                  horizontalPadding: 14,
                  fontSize: 17,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      FocusScope.of(context).unfocus();

                      final p = await Navigator.of(context).push<DeliveryPoint>(
                        MaterialPageRoute(
                          builder: (_) => MapPickerScreen(
                            initial: LatLng(widget.lat, widget.lon),
                            title: 'Точка доставки',
                          ),
                        ),
                      );
                      if (!mounted || p == null) return;

                      setState(() {
                        _pickedOnMap = p;
                        _bazar = null;
                        _passage = null;
                        _container = null;
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: DeliveryPointSheet._tileBorder),
          const SizedBox(height: 16),

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
                  height: 52,
                  radius: 16,
                  horizontalPadding: 18,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RefSuggestField<PassageRef>(
                  controller: _passageCtrl,
                  hint: 'Проход',
                  fetch: _fetchPassages,
                  onSelected: _onPassageSelected,
                  onTextEdited: () => _passage = null,
                  height: 52,
                  radius: 16,
                  horizontalPadding: 18,
                  fontSize: 16,
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
              child: Text(_submitting ? 'Проверяем…' : 'Далее'),
            ),
          ),
        ],
      ),
    );
  }
}
