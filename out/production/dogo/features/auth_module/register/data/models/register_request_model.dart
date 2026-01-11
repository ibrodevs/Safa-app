import 'package:dio/dio.dart';

enum UserRole { client, carrier }

extension UserRoleX on UserRole {
  String get apiValue => this == UserRole.client ? 'client' : 'carrier';
}

UserRole userRoleFromApi(String value) {
  switch (value) {
    case 'carrier':
      return UserRole.carrier;
    case 'client':
    default:
      return UserRole.client;
  }
}

class RegisterRequest {
  final String phoneNumber;
  final String firstName;
  final String lastName;
  final String? avatarPath;
  final UserRole role;
  final String password;
  final String passwordConfirm;
  final String? idFrontPath;
  final String? idBackPath;

  RegisterRequest({
    required this.phoneNumber,
    required this.firstName,
    required this.lastName,
    this.avatarPath,
    required this.role,
    required this.password,
    required this.passwordConfirm,
    this.idFrontPath,
    this.idBackPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'avatar': avatarPath,
      'role': role.apiValue,
      'password': password,
      'password_confirm': passwordConfirm,
      'id_front': idFrontPath,
      'id_back': idBackPath,
    };
  }

  Future<FormData> toFormData() async {
    final form = FormData.fromMap({
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'role': role.apiValue,
      'password': password,
      'password_confirm': passwordConfirm,
    });

    if (avatarPath != null && avatarPath!.isNotEmpty) {
      form.files.add(
        MapEntry(
          'avatar',
          await MultipartFile.fromFile(
            avatarPath!,
            filename: 'avatar.jpg',
          ),
        ),
      );
    }

    if (idFrontPath != null && idFrontPath!.isNotEmpty) {
      form.files.add(
        MapEntry(
          'id_front',
          await MultipartFile.fromFile(
            idFrontPath!,
            filename: 'id_front.jpg',
          ),
        ),
      );
    }

    if (idBackPath != null && idBackPath!.isNotEmpty) {
      form.files.add(
        MapEntry(
          'id_back',
          await MultipartFile.fromFile(
            idBackPath!,
            filename: 'id_back.jpg',
          ),
        ),
      );
    }

    return form;
  }
}


