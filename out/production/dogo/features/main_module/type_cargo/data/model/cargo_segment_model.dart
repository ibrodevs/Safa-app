class CargoSegment {
  final int id;
  final String name;
  final String icon;
  final String description;

  const CargoSegment({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });

  factory CargoSegment.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic v) {
      if (v is int) return v;
      if (v is String) {
        return int.tryParse(v) ?? 0;
      }
      if (v is num) return v.toInt();
      return 0;
    }

    String _asString(dynamic v) => v?.toString() ?? '';

    return CargoSegment(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      icon: _asString(json['icon']),
      description: _asString(json['description']),
    );
  }
}
