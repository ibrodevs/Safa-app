import 'package:dogo/data/network/api_service.dart';

import '../model/profile_model.dart';


class ProfileRepository {
  final ApiService _api;
  ProfileRepository(this._api);
  Future<ProfileModel> getProfile() => _api.getProfile();
}