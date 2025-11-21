import 'package:flutter/material.dart';
import '../../../../data/network/model/api_exeptions_model.dart';
import '../data/models/register_request_model.dart';
import '../data/models/register_response_model.dart';
import '../data/repo/auth_repo.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;

  AuthProvider(this._repo);

  UserRole? _role;
  bool _loading = false;
  String? _error;
  RegisterResponse? _user;

  UserRole? get role => _role;
  bool get loading => _loading;
  String? get error => _error;
  RegisterResponse? get user => _user;

  void setRole(UserRole role) {
    _role = role;
    notifyListeners();
  }

  Future<bool> register({
    required String phoneNumber,
    required String firstName,
    required String lastName,
    required String password,
    required String passwordConfirm,
    String? avatarPath,
    String? idFront,
    String? idBack,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    final request = RegisterRequest(
      phoneNumber: phoneNumber,
      firstName: firstName,
      lastName: lastName,
      avatarPath: avatarPath,
      role: _role ?? UserRole.client,
      password: password,
      passwordConfirm: passwordConfirm,
      idFrontPath: idFront,
      idBackPath: idBack,
    );

    try {
      _user = await _repo.register(request);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _loading = false;
      _error = e.message;
      notifyListeners();
      return false;
    }
  }
}
