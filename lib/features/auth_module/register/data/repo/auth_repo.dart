import '../../../../../data/network/api_service.dart';
import '../models/register_request_model.dart';
import '../models/register_response_model.dart';


class AuthRepository {
  final ApiService api;

  AuthRepository(this.api);

  Future<RegisterResponse> register(RegisterRequest body) {
    return api.postRegister(body);
  }
}