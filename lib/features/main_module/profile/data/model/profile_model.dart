class ProfileUser {
  final int id;
  final String role;
  final String firstName;
  final String phoneNumber;

  ProfileUser({
    required this.id,
    required this.role,
    required this.firstName,
    required this.phoneNumber,
  });

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      role: json['role']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
    );
  }
}

class ProfileModel {
  final ProfileUser user;
  final String firstName;
  final String lastName;
  final String? avatar;
  final DateTime? createdAt;

  ProfileModel({
    required this.user,
    required this.firstName,
    required this.lastName,
    required this.avatar,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return ProfileModel(
      user: userJson is Map<String, dynamic>
          ? ProfileUser.fromJson(userJson)
          : ProfileUser(
        id: 0,
        role: '',
        firstName: '',
        phoneNumber: '',
      ),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  String get fullName {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isEmpty && l.isEmpty) return '';
    if (l.isEmpty) return f;
    return '$f $l';
  }
}
