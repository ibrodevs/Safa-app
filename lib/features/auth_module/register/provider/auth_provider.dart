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

  String? _pendingPhone;
  String? _pendingPassword;
  bool _loggedIn = false;

  UserRole? get role => _role;
  bool get loading => _loading;
  String? get error => _error;
  RegisterResponse? get user => _user;
  String? get pendingPhone => _pendingPhone;
  bool get loggedIn => _loggedIn;

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
      _pendingPhone = phoneNumber;
      _pendingPassword = password;
      _loggedIn = false;
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      final alreadyExists = e.statusCode == 400 &&
          e.message.toLowerCase().contains('уже существует');
      if (alreadyExists) {
        try {
          await _repo.login(
            phoneNumber: phoneNumber,
            password: password,
          );
          _pendingPhone = phoneNumber;
          _pendingPassword = password;
          _loggedIn = true;
          _error = null;
          _loading = false;
          notifyListeners();
          return true;
        } on ApiException catch (e2) {
          _loading = false;
          _error = e2.message;
          notifyListeners();
          return false;
        }
      }
      _loading = false;
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendWhatsappCode() async {
    final phone = _pendingPhone;
    if (phone == null || phone.isEmpty) {
      _error = 'Нет номера телефона для подтверждения';
      notifyListeners();
      return false;
    }
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.sendWhatsappCode(phone);
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

  Future<bool> verifyCodeAndLogin({required String code}) async {
    final phone = _pendingPhone;
    final password = _pendingPassword;

    if (phone == null || phone.isEmpty || password == null || password.isEmpty) {
      _error = 'Нет данных для входа';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.verifyCode(phone: phone, code: code);
      if (!_loggedIn) {
        await _repo.login(phoneNumber: phone, password: password);
        _loggedIn = true;
      }
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
