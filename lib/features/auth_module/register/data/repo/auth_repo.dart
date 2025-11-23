import '../../../../../data/network/api_service.dart';
import '../models/register_request_model.dart';
import '../models/register_response_model.dart';

class AuthRepository {
  final ApiService api;

  AuthRepository(this.api);

  Future<RegisterResponse> register(RegisterRequest body) {
    return api.postRegister(body);
  }

  Future<void> sendWhatsappCode(String phoneNumber) {
    //return api.postDebugWhatsappCode(phoneNumber: phoneNumber);
    return api.postWhatsappCode(phoneNumber: phoneNumber);
  }

  Future<void> verifyCode({required String phone, required String code}) {
    return api.postVerifyCode(phone: phone, code: code);
  }

  Future<void> login({required String phoneNumber, required String password}) {
    return api.postToken(phoneNumber: phoneNumber, password: password);
  }

  Future<void> uploadSelfie({
    required String selfiePath,
    required String phone,
  }) {
    return api.postSelfie(selfiePath: selfiePath, phone: phone);
  }

  Future<int> carrierWait({required String phone}) {
    return api.postCarrierWait(phone: phone);
  }
}
