import 'package:dogo/data/network/api_service.dart';

import '../model/profile_model.dart';


class ProfileRepository {
  final ApiService _api;
  ProfileRepository(this._api);
  Future<ProfileModel> getProfile() => _api.getProfile();
  Future<ProfileModel> patchProfile({
    required int? id,
    String? firstName,
    String? city,
    String? avatar,
    int? rate,
    int? clientRateCount,
  }) {
    return _api.patchProfile(
      id: id,
      firstName: firstName,
      city: city,
      avatar: avatar,
      rate: rate,
      clientRateCount: clientRateCount,
    );
  }
}