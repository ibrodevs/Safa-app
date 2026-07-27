import 'package:flutter/foundation.dart';
import 'package:dogo/data/network/api_service.dart';
import 'package:dogo/data/network/model/api_exeptions_model.dart';

import '../data/model/profile_model.dart';
import '../data/repo/profile_repo.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _repo;

  ProfileProvider({ProfileRepository? repo})
    : _repo = repo ?? ProfileRepository(ApiService.instance);

  ProfileModel? _profile;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  ProfileModel? get profile => _profile;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;

  Future<void> loadProfile() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _repo.getProfile();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e, st) {
      _error = 'Не удалось загрузить профиль';
      if (kDebugMode) {
        print('ProfileProvider.loadProfile error: $e\n$st');
      }
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? firstName,
    String? city,
    String? avatar,
    int? rate,
    int? clientRateCount,
  }) async {
    final current = _profile;
    if (current == null) {
      _error = 'Профиль не загружен';
      notifyListeners();
      return false;
    }

    _saving = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _repo.patchProfile(
        id: current.id,
        firstName: firstName,
        city: city,
        avatar: avatar,
        rate: rate,
        clientRateCount: clientRateCount,
      );
      _profile = updated;
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e, st) {
      _error = 'Не удалось обновить профиль';
      if (kDebugMode) {
        print('ProfileProvider.updateProfile error: $e\n$st');
      }
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAccount() async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.deleteAccount();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e, st) {
      _error = 'Не удалось удалить аккаунт';
      if (kDebugMode) {
        print('ProfileProvider.deleteAccount error: $e\n$st');
      }
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
