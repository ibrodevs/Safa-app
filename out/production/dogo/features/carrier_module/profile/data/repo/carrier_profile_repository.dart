import 'package:dogo/data/network/api_service.dart';
import '../model/carrier_day_stats.dart';
import '../model/carrier_profile_model.dart';

class CarrierProfileRepository {
  final ApiService _api;

  CarrierProfileRepository(this._api);

  Future<CarrierProfileModel> getProfile() => _api.getCarrierProfile();

  Future<CarrierDayStats> getStatsForDate({required DateTime date}) {
    return _api.getCarrierStatsForDate(date);
  }
}
