class ProfileModel {
  final int? id;
  final String role;
  final String phoneNumber;
  final String firstName;
  final String? city;
  final String? avatar;
  final int rate;
  final int clientRateCount;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    required this.role,
    required this.phoneNumber,
    required this.firstName,
    required this.city,
    required this.avatar,
    required this.rate,
    required this.clientRateCount,
    required this.createdAt,
  });

  ProfileModel copyWith({
    int? id,
    String? role,
    String? phoneNumber,
    String? firstName,
    String? city,
    String? avatar,
    int? rate,
    int? clientRateCount,
    DateTime? createdAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      city: city ?? this.city,
      avatar: avatar ?? this.avatar,
      rate: rate ?? this.rate,
      clientRateCount: clientRateCount ?? this.clientRateCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toPatchJson({
    String? firstName,
    String? city,
    String? avatar,
    int? rate,
    int? clientRateCount,
  }) {
    final m = <String, dynamic>{};
    if (firstName != null) m['first_name'] = firstName;
    if (city != null) m['city'] = city;
    if (avatar != null) m['avatar'] = avatar;
    if (rate != null) m['rate'] = rate;
    if (clientRateCount != null) m['client_rate_count'] = clientRateCount;
    return m;
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '0') ?? 0;
    }

    DateTime _asDate(dynamic v) {
      if (v == null) return DateTime.now();
      final s = v.toString();
      return DateTime.tryParse(s) ?? DateTime.now();
    }

    final dynamic cityRaw = json['city'];
    final dynamic avatarRaw = json['avatar'];

    return ProfileModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      role: json['role']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      city: cityRaw == null ? null : cityRaw.toString(),
      avatar: avatarRaw == null ? null : avatarRaw.toString(),
      rate: _asInt(json['rate']),
      clientRateCount: _asInt(json['client_rate_count']),
      createdAt: _asDate(json['created_at']),
    );
  }
}
