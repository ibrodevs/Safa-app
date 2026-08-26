class DeliveryPoint {
  final String title;
  final String subtitle;
  final double? lat;
  final double? lon;

  final String? _bazar;
  final String? _district;
  final String? _passage;
  final String? _container;
  final String? _q;

  const DeliveryPoint({
    required this.title,
    required this.subtitle,
    this.lat,
    this.lon,
    String? bazar,
    String? district,
    String? passage,
    String? container,
    String? q,
  }) : _bazar = bazar,
       _district = district,
       _passage = passage,
       _container = container,
       _q = q;

  // Разбираем только собственные подписи — «Базар: X · Проход: Y» и легаси
  // «Контейнер 125 • Проход 4». Метка обязана стоять в начале фрагмента.
  // Раньше шаблоны ловили голое слово в любом месте строки, и адрес от
  // геокодера («Дордой базар, Кожевенная улица») превращался в мусорный
  // `bazar` без прохода и контейнера — backend отвечал на такой заказ 400.
  static RegExp _labelPattern(String label) => RegExp(
    '(?:^|[·•])\\s*$label(?:\\s*:\\s*|\\s+)([^•·]+)',
    caseSensitive: false,
  );

  static final RegExp _bazarPattern = _labelPattern('Базар');
  static final RegExp _districtPattern = _labelPattern('Район');
  static final RegExp _containerPattern = _labelPattern('Контейнер');
  static final RegExp _passagePattern = _labelPattern('Проход');

  static String? _clean(String? value) {
    final cleaned = value?.trim() ?? '';
    return cleaned.isEmpty ? null : cleaned;
  }

  static String? _extract(String source, RegExp pattern) {
    final match = pattern.firstMatch(source);
    return _clean(match?.group(1));
  }

  String get _combinedSource => '$title · $subtitle';

  String? get container =>
      _clean(_container) ?? _extract(_combinedSource, _containerPattern);

  String? get passage =>
      _clean(_passage) ?? _extract(_combinedSource, _passagePattern);

  String? get district =>
      _clean(_district) ?? _extract(_combinedSource, _districtPattern);

  String? get bazar {
    final explicit = _clean(_bazar);
    if (explicit != null) return explicit;

    final extracted = _extract(_combinedSource, _bazarPattern);
    if (extracted != null) return extracted;

    // Legacy point picker used the bazar name itself as title.
    if ((container != null || passage != null) &&
        !title.contains('Базар:') &&
        !title.contains('Район:') &&
        !title.contains('Проход:') &&
        !title.contains('Контейнер:')) {
      return _clean(title);
    }
    return null;
  }

  String? get q => _clean(_q);

  String get compactTitle {
    final parts = <String>[];
    final b = bazar;
    final d = district;
    if (b != null) parts.add('Базар: $b');
    if (d != null) parts.add('Район: $d');
    if (parts.isNotEmpty) return parts.join(' · ');

    final p = passage;
    final c = container;
    if (p != null) parts.add('Проход: $p');
    if (c != null) parts.add('Контейнер: $c');
    return parts.isNotEmpty ? parts.join(' · ') : title.trim();
  }

  String get compactSubtitle {
    final parts = <String>[];
    final p = passage;
    final c = container;
    if (p != null) parts.add('Проход: $p');
    if (c != null) parts.add('Контейнер: $c');
    if (parts.isNotEmpty) return parts.join(' · ');

    final raw = subtitle.trim();
    if (raw == title.trim()) return '';
    return raw;
  }

  String get compactAddress {
    final parts = <String>[];
    final b = bazar;
    final d = district;
    final p = passage;
    final c = container;
    if (b != null) parts.add('Базар: $b');
    if (d != null) parts.add('Район: $d');
    if (p != null) parts.add('Проход: $p');
    if (c != null) parts.add('Контейнер: $c');
    if (parts.isNotEmpty) return parts.join(' · ');
    return title.trim().isNotEmpty ? title.trim() : subtitle.trim();
  }

  /// Контейнер описан полностью только когда известны все три части.
  /// Backend отклоняет частичный набор («Для контейнера нужны все поля»),
  /// поэтому неполные данные отправлять нельзя — точка уйдёт по координатам.
  bool get hasFullContainerAddress =>
      (bazar ?? '').isNotEmpty &&
      (passage ?? '').isNotEmpty &&
      (container ?? '').isNotEmpty;

  /// Backend ограничивает подпись точки 255 символами.
  static String _fitTitle(String value) =>
      value.length <= 255 ? value : value.substring(0, 255).trimRight();

  Map<String, dynamic> toStopJson() {
    final full = hasFullContainerAddress;
    final label = compactAddress.isNotEmpty ? compactAddress : title;

    return <String, dynamic>{
      'title': _fitTitle(label),
      'lat': lat,
      'lon': lon,
      'bazar': full ? bazar! : '',
      'passage': full ? passage! : '',
      'container': full ? container! : '',
      'q': q ?? '',
    };
  }
}
