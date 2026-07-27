import 'package:flutter/foundation.dart';
import 'package:dogo/data/network/api_service.dart';
import 'package:dogo/data/network/model/api_exeptions_model.dart';
import '../data/model/support_model.dart';
import '../data/repo/profile_repo.dart';

class SupportProvider extends ChangeNotifier {
  final ProfileRepository _repo;

  SupportProvider({ProfileRepository? repo})
    : _repo = repo ?? ProfileRepository(ApiService.instance);

  SupportModel? _support;
  bool _loading = false;
  String? _error;

  SupportModel? get support => _support;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchSupport() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _support = await _repo.getSupport();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (e, st) {
      _error = 'Не удалось загрузить данные поддержки';
      if (kDebugMode) {
        print('SupportProvider.fetchSupport error: $e\n$st');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
