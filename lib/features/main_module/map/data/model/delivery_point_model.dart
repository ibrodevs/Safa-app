class DeliveryPoint {
  final String title;
  final String subtitle;
  final double? lat;
  final double? lon;

  final String? _bazar;
  final String? _passage;
  final String? _container;
  final String? _q;

  const DeliveryPoint({
    required this.title,
    required this.subtitle,
    this.lat,
    this.lon,
    String? bazar,
    String? passage,
    String? container,
    String? q,
  }) : _bazar = bazar,
       _passage = passage,
       _container = container,
       _q = q;

  static final RegExp _containerPattern = RegExp(
    r'Контейнер\s*:?\s*([^•]+)',
    caseSensitive: false,
  );
  static final RegExp _passagePattern = RegExp(
    r'Проход\s*:?\s*([^•]+)',
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

  String? get container =>
      _clean(_container) ?? _extract(subtitle, _containerPattern);

  String? get passage =>
      _clean(_passage) ?? _extract(subtitle, _passagePattern);

  String? get bazar {
    final explicit = _clean(_bazar);
    if (explicit != null) return explicit;

    // MapPicker returns the bazar in title and the selected container/passage
    // in subtitle. Some sheets rebuild the point with empty metadata, so
    // restore it here before creating the shipment payload.
    if (container != null || passage != null) return _clean(title);

    return null;
  }

  String? get q => _clean(_q);

  Map<String, dynamic> toStopJson() => <String, dynamic>{
    'title': title,
    'lat': lat,
    'lon': lon,
    'bazar': bazar ?? '',
    'passage': passage ?? '',
    'container': container ?? '',
    'q': q ?? '',
  };
}
