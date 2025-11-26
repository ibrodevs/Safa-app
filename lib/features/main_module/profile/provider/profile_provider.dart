// lib/features/main_module/profile/provider/profile_provider.dart

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
  String? _error;

  ProfileModel? get profile => _profile;
  bool get loading => _loading;
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
}
