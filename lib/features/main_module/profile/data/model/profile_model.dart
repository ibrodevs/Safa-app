class ProfileModel {
  final String role;
  final String phoneNumber;
  final String firstName;
  final String? city;
  final String? avatar;
  final int rate;
  final int clientRateCount;
  final DateTime createdAt;

  ProfileModel({
    required this.role,
    required this.phoneNumber,
    required this.firstName,
    required this.city,
    required this.avatar,
    required this.rate,
    required this.clientRateCount,
    required this.createdAt,
  });

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
