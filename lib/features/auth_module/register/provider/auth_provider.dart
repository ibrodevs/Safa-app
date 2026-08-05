import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/network/api_service.dart';
import '../../../../data/network/model/api_exeptions_model.dart';
import '../../../../data/services/secure_storage_service.dart';
import '../data/models/register_request_model.dart';
import '../data/models/register_response_model.dart';
import '../data/repo/auth_repo.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo;

  AuthProvider(this._repo);

  UserRole? _role;
  SpecialistType? _specialistType;
  bool _loading = false;
  String? _error;
  RegisterResponse? _user;

  String? _pendingPhone;
  bool _loggedIn = false;

  UserRole? get role => _role;
  SpecialistType? get specialistType => _specialistType;
  bool get loading => _loading;
  String? get error => _error;
  RegisterResponse? get user => _user;
  String? get pendingPhone => _pendingPhone;
  bool get loggedIn => _loggedIn;

  Future<String> _loadRoleFromProfile() async {
    final profile = await ApiService.instance.getProfile();
    final role = profile.role.trim().isNotEmpty
        ? profile.role.trim()
        : 'client';
    _role = role == 'carrier' ? UserRole.carrier : UserRole.client;
    return role;
  }

  Future<bool> restoreSession() async {
    final access = await SecureStorageService().getAccessToken();
    final refresh = await SecureStorageService().getRefreshToken();
    if ((access == null || access.isEmpty) &&
        (refresh == null || refresh.isEmpty)) {
      _loggedIn = false;
      return false;
    }

    try {
      if (access != null && access.isNotEmpty) {
        await ApiService.instance.setBearer(access);
      }
      final role = await _loadRoleFromProfile();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_role', role);
      _loggedIn = true;
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      await SecureStorageService().resetAll();
      await ApiService.instance.setBearer(null);
      _loggedIn = false;
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  void setRole(UserRole role) {
    _role = role;
    if (role == UserRole.client) _specialistType = null;
    notifyListeners();
  }

  void setSpecialistType(SpecialistType type) {
    _role = UserRole.carrier;
    _specialistType = type;
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
      specialistType: _specialistType,
      password: password,
      passwordConfirm: passwordConfirm,
      idFrontPath: idFront,
      idBackPath: idBack,
    );

    try {
      _user = await _repo.register(request);
      _pendingPhone = phoneNumber;
      _loggedIn = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_phone', phoneNumber);

      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      final alreadyExists =
          e.statusCode == 400 &&
          (e.message.toLowerCase().contains('уже существует') ||
              e.message.toLowerCase().contains('уже зарегистрирован'));
      if (alreadyExists) {
        _loading = false;
        _error =
            'Аккаунт с этим номером уже существует. Войдите через экран авторизации.';
        notifyListeners();
        return false;
      }
      _loading = false;
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String phoneNumber,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.login(phoneNumber: phoneNumber, password: password);
      final role = await _loadRoleFromProfile();
      _loggedIn = true;
      _pendingPhone = phoneNumber;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('pending_phone', phoneNumber);
      await prefs.setString('user_role', role);
      await prefs.remove('carrier_pending');

      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _loading = false;
      _loggedIn = false;
      _error = e.statusCode == 401
          ? 'Неверный номер телефона или пароль'
          : e.message;
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
      await _repo.uploadSelfie(selfiePath: path, phone: phone);
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
