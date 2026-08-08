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

  static final RegExp _bazarPattern = RegExp(
    r'Базар\s*:?\s*([^•·]+)',
    caseSensitive: false,
  );
  static final RegExp _districtPattern = RegExp(
    r'Район\s*:?\s*([^•·]+)',
    caseSensitive: false,
  );
  static final RegExp _containerPattern = RegExp(
    r'Контейнер\s*:?\s*([^•·]+)',
    caseSensitive: false,
  );
  static final RegExp _passagePattern = RegExp(
    r'Проход\s*:?\s*([^•·]+)',
    caseSensitive: false,
  );

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

  Map<String, dynamic> toStopJson() => <String, dynamic>{
    'title': compactAddress.isNotEmpty ? compactAddress : title,
    'lat': lat,
    'lon': lon,
    'bazar': bazar ?? '',
    'passage': passage ?? '',
    'container': container ?? '',
    'q': q ?? '',
  };
}
