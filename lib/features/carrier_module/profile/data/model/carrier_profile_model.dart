class CarrierProfileModel {
  final String role;
  final String phoneNumber;
  final String firstName;
  final String? city;
  final String? avatar;
  final int rate;
  final int clientRateCount;
  final DateTime createdAt;

  CarrierProfileModel({
    required this.role,
    required this.phoneNumber,
    required this.firstName,
    required this.city,
    required this.avatar,
    required this.rate,
    required this.clientRateCount,
    required this.createdAt,
  });

  factory CarrierProfileModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '0') ?? 0;
    }

    DateTime asDate(dynamic v) {
      if (v == null) return DateTime.now();
      final s = v.toString();
      return DateTime.tryParse(s) ?? DateTime.now();
    }

    final dynamic cityRaw = json['city'];
    final dynamic avatarRaw = json['avatar_url'] ?? json['avatar'];

    return CarrierProfileModel(
      role: json['role']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      city: cityRaw?.toString(),
      avatar: avatarRaw?.toString(),
      rate: asInt(json['rate']),
      clientRateCount: asInt(json['client_rate_count']),
      createdAt: asDate(json['created_at']),
    );
  }
}
