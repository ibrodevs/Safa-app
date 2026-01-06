class DeliveryPoint {
  final String title;
  final String subtitle;
  final double? lat;
  final double? lon;

  final String? bazar;
  final String? passage;
  final String? container;
  final String? q;

  const DeliveryPoint({
    required this.title,
    required this.subtitle,
    this.lat,
    this.lon,
    this.bazar,
    this.passage,
    this.container,
    this.q,
  });

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
