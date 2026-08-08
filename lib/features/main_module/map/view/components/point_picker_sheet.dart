import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/design/app_design.dart';
import '../../../../../core/widgets/app_widgets.dart';
import '../../data/model/delivery_point_model.dart';
import '../../data/model/delivery_refs_models.dart';
import '../../data/repo/delivery_refs_repository.dart';
import '../widgets/ref_suggest_field.dart';
import 'map_picker_screen.dart';

/// Роль выбираемой точки. Влияет только на тексты — логика одна.
enum PointPickerMode {
  from('Точка отправки', 'Откуда забрать', 'Выберите базар отправки'),
  destination('Точка доставки', 'Куда доставить', 'Выберите базар доставки'),
  intermediate('Остановка', 'Промежуточная точка', 'Выберите базар остановки');

  const PointPickerMode(this.title, this.subtitle, this.bazarHint);

  final String title;
  final String subtitle;
  final String bazarHint;
}

/// Единый лист выбора точки маршрута.
///
/// Заменяет три почти идентичных файла (`from_point_sheet.dart`,
/// `deliveri_point_sheet.dart`, `intermediate_point_sheet.dart`) — ~1300 строк
/// дублированного кода. Логика поиска по справочникам, ручного ввода номера
/// контейнера и выбора точки на карте сохранена без изменений, включая
/// восстановление координат из справочника перед возвратом точки.
class PointPickerSheet extends StatefulWidget {
  const PointPickerSheet({
    super.key,
    required this.mode,
    required this.lat,
    required this.lon,
    this.headline,
    this.headlineSubtitle,
    this.stopNumber,
  });

  final PointPickerMode mode;

  /// Стартовые координаты для экрана выбора на карте.
  final double lat;
  final double lon;

  /// Текущий адрес, показываемый в шапке (например, GPS-адрес).
  final String? headline;
  final String? headlineSubtitle;

  /// Номер остановки для [PointPickerMode.intermediate].
  final int? stopNumber;

  @override
  State<PointPickerSheet> createState() => _PointPickerSheetState();
}

class _PointPickerSheetState extends State<PointPickerSheet> {
  final TextEditingController _bazarCtrl = TextEditingController();
  final TextEditingController _containerCtrl = TextEditingController();
  final TextEditingController _passageCtrl = TextEditingController();

  final DeliveryRefsRepository _refs = DeliveryRefsRepository();

  DeliveryPoint? _pickedOnMap;
  BazarRef? _bazar;
  PassageRef? _passage;
  ContainerRef? _container;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _bazarCtrl.dispose();
    _containerCtrl.dispose();
    _passageCtrl.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.mode == PointPickerMode.intermediate &&
        widget.stopNumber != null) {
      return 'Остановка ${widget.stopNumber}';
    }
    return widget.mode.title;
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
        .map(
          (p) =>
              RefSuggestion(label: p.number, sublabel: p.bazarName, value: p),
        )
        .toList();
  }

  Future<List<RefSuggestion<ContainerRef>>> _fetchContainers(String q) async {
    final list = await _refs.searchContainers(
      query: q,
      bazarId: _bazar?.id,
      passageId: _passage?.id,
    );
    return list
        .map(
          (c) => RefSuggestion(
            label: 'Контейнер ${c.number}',
            sublabel: '${c.passageNumber} · ${c.bazarName}',
            fillText: c.number,
            value: c,
          ),
        )
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
      _error = null;
    });
  }

  void _onPassageSelected(RefSuggestion<PassageRef> s) {
    final p = s.value;
    setState(() {
      _passage = p;
      _pickedOnMap = null;
      _container = null;
      _containerCtrl.clear();
      _error = null;
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
      _error = null;
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

  Future<void> _openMapPicker() async {
    FocusScope.of(context).unfocus();

    final picked = await Navigator.of(context).push<DeliveryPoint>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initial: LatLng(widget.lat, widget.lon),
          title: _title,
        ),
      ),
    );
    if (!mounted || picked == null) return;

    setState(() {
      _pickedOnMap = picked;
      _bazar = null;
      _passage = null;
      _container = null;
      _bazarCtrl.text = picked.bazar?.trim().isNotEmpty == true
          ? picked.bazar!.trim()
          : picked.title;
      _containerCtrl.text = picked.container ?? '';
      _passageCtrl.text = picked.passage ?? '';
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();

    // Точка, выбранная на карте, уже содержит координаты и метаданные
    // контейнера — возвращаем её как есть, ничего не «обнуляя».
    final pickedOnMap = _pickedOnMap;
    if (pickedOnMap != null) {
      Navigator.of(context).pop(pickedOnMap);
      return;
    }

    var container = _container;

    // Пользователь ввёл номер контейнера руками — ищем его в справочнике,
    // чтобы у точки всегда были координаты (иначе backend вернёт 400).
    if (container == null && _containerCtrl.text.trim().isNotEmpty) {
      setState(() => _submitting = true);
      try {
        final found = await _refs.searchContainers(
          query: _containerCtrl.text.trim(),
          bazarId: _bazar?.id,
          passageId: _passage?.id,
          pageSize: 1,
        );
        if (found.isNotEmpty) container = found.first;
      } catch (_) {
        // Сетевую ошибку показываем ниже общим сообщением.
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      if (!mounted) return;
    }

    if (container == null ||
        container.latValue == null ||
        container.lonValue == null) {
      setState(
        () =>
            _error = 'Выберите контейнер из списка или укажите точку на карте',
      );
      return;
    }

    final bazarName = _bazarCtrl.text.trim().isNotEmpty
        ? _bazarCtrl.text.trim()
        : container.bazarName;

    Navigator.of(context).pop(
      DeliveryPoint(
        title: bazarName.isNotEmpty ? bazarName : _title,
        subtitle: _subtitleFrom(container.number, container.passageNumber),
        lat: container.latValue,
        lon: container.lonValue,
        bazar: bazarName,
        container: container.number,
        passage: container.passageNumber,
        q: '',
      ),
    );
  }

  bool get _hasSelection =>
      _pickedOnMap != null ||
      _container != null ||
      _containerCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: _title,
      subtitle: widget.headline?.trim().isNotEmpty == true
          ? widget.headline
          : widget.mode.subtitle,
      footer: Column(
        children: [
          AppFormError(message: _error),
          if (_error != null) AppSpacing.gapSm,
          AppPrimaryButton(
            label: 'Подтвердить точку',
            loadingLabel: 'Проверяем…',
            loading: _submitting,
            enabled: _hasSelection,
            onPressed: _submit,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.headlineSubtitle != null &&
              widget.headlineSubtitle!.isNotEmpty) ...[
            Text(widget.headlineSubtitle!, style: AppTypography.caption),
            AppSpacing.gapSm,
          ],
          RefSuggestField<BazarRef>(
            controller: _bazarCtrl,
            hint: widget.mode.bazarHint,
            label: 'Базар',
            fetch: _fetchBazars,
            onSelected: _onBazarSelected,
            onTextEdited: () {
              _bazar = null;
              _pickedOnMap = null;
            },
          ),
          AppSpacing.gapSm,
          AppSecondaryButton(
            label: 'Выбрать на карте',
            icon: Icons.map_outlined,
            accent: true,
            size: AppButtonSize.medium,
            onPressed: _submitting ? null : _openMapPicker,
          ),
          AppSpacing.gapLg,
          const Divider(height: 1, color: AppColors.border),
          AppSpacing.gapLg,
          Text('Контейнер и проход', style: AppTypography.cardTitle),
          AppSpacing.gapSm,
          RefSuggestField<ContainerRef>(
            controller: _containerCtrl,
            hint: 'Номер контейнера',
            label: 'Контейнер',
            fetch: _fetchContainers,
            onSelected: _onContainerSelected,
            onTextEdited: () {
              _container = null;
              if (_error != null) setState(() => _error = null);
            },
          ),
          AppSpacing.gapSm,
          RefSuggestField<PassageRef>(
            controller: _passageCtrl,
            hint: 'Номер прохода',
            label: 'Проход',
            fetch: _fetchPassages,
            onSelected: _onPassageSelected,
            onTextEdited: () => _passage = null,
          ),
          if (_pickedOnMap != null) ...[
            AppSpacing.gapMd,
            _PickedOnMapNotice(point: _pickedOnMap!),
          ],
        ],
      ),
    );
  }
}

class _PickedOnMapNotice extends StatelessWidget {
  const _PickedOnMapNotice({required this.point});

  final DeliveryPoint point;

  @override
  Widget build(BuildContext context) {
    final details = point.subtitle.trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: AppRadius.allSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: AppColors.success,
          ),
          AppSpacing.hGapXs,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Точка выбрана на карте',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  details.isEmpty ? point.title : details,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
