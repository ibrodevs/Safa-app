import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_phone', phoneNumber);

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

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pending_phone', phoneNumber);

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

    if (phone == null || phone.isEmpty) {
      _error = 'Нет номера телефона для подтверждения';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.verifyCode(phone: phone, code: code);

      _loggedIn = true;
      _loading = false;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('pending_phone', phone);

      final role = _role ?? UserRole.client;
      final roleCode = role == UserRole.carrier ? 'carrier' : 'client';
      await prefs.setString('user_role', roleCode);

      return true;
    } on ApiException catch (e) {
      _loading = false;
      _error = e.message;
      notifyListeners();
      return false;
    }
  }


  Future<bool> uploadSelfie(String path) async {
    final phone = _pendingPhone;
    if (phone == null || phone.isEmpty) {
      _error = 'Нет номера телефона для селфи';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.uploadSelfie(
        selfiePath: path,
        phone: phone,
      );
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

  Future<int?> carrierWait() async {
    var phone = _pendingPhone;

    if (phone == null || phone.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      phone = prefs.getString('pending_phone');
      _pendingPhone = phone;
    }

    if (phone == null || phone.isEmpty) {
      _error = 'Нет номера телефона для подтверждения';
      notifyListeners();
      return null;
    }

    try {
      final status = await _repo.carrierWait(phone: phone);
      _error = null;
      notifyListeners();
      return status;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    }
  }
}
