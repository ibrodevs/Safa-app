// lib/features/main_module/profile/provider/carrier_profile_provider.dart

import 'package:flutter/foundation.dart';
import '../data/model/carrier_day_stats.dart';
import '../data/model/carrier_profile_model.dart';
import '../data/repo/carrier_profile_repository.dart';

class CarrierProfileProvider extends ChangeNotifier {
  final CarrierProfileRepository _repo;

  CarrierProfileProvider(this._repo);

  CarrierProfileModel? _profile;
  final Map<String, CarrierDayStats> _statsCache = {};
  bool _loadingProfile = false;
  bool _loadingStats = false;
  String? _error;
  DateTime? _selectedDate;

  CarrierProfileModel? get profile => _profile;
  bool get loading => _loadingProfile;
  bool get statsLoading => _loadingStats;
  String? get error => _error;
  DateTime? get selectedDate => _selectedDate;

  Future<void> load() async {
    _loadingProfile = true;
    _error = null;
    notifyListeners();

    try {
      final prof = await _repo.getProfile();
      _profile = prof;

      final today = DateTime.now();
      _selectedDate = _normalize(today);

      await _loadStatsFor(_selectedDate!);
    } catch (e, st) {
      _error = e.toString();
      if (kDebugMode) {
        print('CarrierProfileProvider.load error: $e\n$st');
      }
    } finally {
      _loadingProfile = false;
      notifyListeners();
    }
  }

  List<DateTime> get days {
    if (_profile == null) return [];
    final created = _normalize(_profile!.createdAt);
    final today = _normalize(DateTime.now());

    final res = <DateTime>[];
    for (var d = today; !d.isBefore(created); d = d.subtract(const Duration(days: 1))) {
      res.add(d);
    }
    return res;
  }

  Future<void> selectDate(DateTime date) async {
    final normalized = _normalize(date);
    _selectedDate = normalized;
    notifyListeners();
    await _loadStatsFor(normalized);
  }

  CarrierDayStats? statsFor(DateTime date) {
    return _statsCache[_key(_normalize(date))];
  }

  CarrierDayStats? get selectedStats {
    final d = _selectedDate;
    if (d == null) return null;
    return statsFor(d);
  }

  int? get selectedChangePercent {
    return selectedStats?.changePercentVsPrev;
  }

  Future<void> _loadStatsFor(DateTime date) async {
    final key = _key(date);
    if (_statsCache.containsKey(key)) return;

    _loadingStats = true;
    notifyListeners();

    try {
      final stat = await _repo.getStatsForDate(date: date);
      _statsCache[key] = stat;
    } catch (e, st) {
      _error = e.toString();
      if (kDebugMode) {
        print('CarrierProfileProvider._loadStatsFor error: $e\n$st');
      }
    } finally {
      _loadingStats = false;
      notifyListeners();
    }
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
