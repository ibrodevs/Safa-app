class DeliveryAutocompleteResult {
  final String title;
  final String address;
  final double lat;
  final double lon;

  const DeliveryAutocompleteResult({
    required this.title,
    required this.address,
    required this.lat,
    required this.lon,
  });

  factory DeliveryAutocompleteResult.fromJson(Map<String, dynamic> json) {
    final latRaw = json['lat'];
    final lonRaw = json['lon'];

    double toDouble_(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0;
      return 0;
    }

    return DeliveryAutocompleteResult(
      title: json['title']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      lat: toDouble_(latRaw),
      lon: toDouble_(lonRaw),
    );
  }
}
