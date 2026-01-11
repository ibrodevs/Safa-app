import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/network/api_service.dart';
import '../../data/services/secure_storage_service.dart';

final class LogoutService {
  const LogoutService();

  Future<void> logout() async {
    final storage = SecureStorageService();
    await storage.resetAll();
    await ApiService.instance.setBearer(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.remove('user_role');
    await prefs.remove('carrier_pending');
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }
}
