import 'package:dogo/features/auth_module/register/data/models/register_request_model.dart';

class RegisterResponse {
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final String? avatar;
  final UserRole role;

  RegisterResponse({
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    this.avatar,
    required this.role,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      phoneNumber: json['phone_number'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      avatar: json['avatar'] as String?,
      role: userRoleFromApi(json['role'] as String? ?? 'client'),
    );
  }
}
