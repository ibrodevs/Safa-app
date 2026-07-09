/// Модели справочников доставки: базары, проходы, контейнеры.
library;

class BazarRef {
  final int id;
  final String name;

  const BazarRef({required this.id, required this.name});

  factory BazarRef.fromJson(Map<String, dynamic> json) {
    return BazarRef(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class PassageRef {
  final int id;
  final int bazarId;
  final String bazarName;
  final String number;

  const PassageRef({
    required this.id,
    required this.bazarId,
    required this.bazarName,
    required this.number,
  });

  factory PassageRef.fromJson(Map<String, dynamic> json) {
    return PassageRef(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bazarId: (json['bazar_id'] as num?)?.toInt() ?? 0,
      bazarName: json['bazar_name']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
    );
  }
}

class ContainerRef {
  final int id;
  final int bazarId;
  final String bazarName;
  final int passageId;
  final String passageNumber;
  final String number;
  final String title;
  final bool isActive;
  final String lat;
  final String lon;
  final String uiLabel;
  final String displayTitle;

  const ContainerRef({
    required this.id,
    required this.bazarId,
    required this.bazarName,
    required this.passageId,
    required this.passageNumber,
    required this.number,
    required this.title,
    required this.isActive,
    required this.lat,
    required this.lon,
    required this.uiLabel,
    required this.displayTitle,
  });

  double? get latValue => double.tryParse(lat);
  double? get lonValue => double.tryParse(lon);

  factory ContainerRef.fromJson(Map<String, dynamic> json) {
    return ContainerRef(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bazarId: (json['bazar_id'] as num?)?.toInt() ?? 0,
      bazarName: json['bazar_name']?.toString() ?? '',
      passageId: (json['passage_id'] as num?)?.toInt() ?? 0,
      passageNumber: json['passage_number']?.toString() ?? '',
      number: json['number']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      isActive: json['is_active'] == true,
      lat: json['lat']?.toString() ?? '',
      lon: json['lon']?.toString() ?? '',
      uiLabel: json['ui_label']?.toString() ?? '',
      displayTitle: json['display_title']?.toString() ?? '',
    );
  }
}
