import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';
  static const _keyKycEnrollment = 'kyc_enrollment_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Reading Keychain/EncryptedSharedPreferences is a platform-channel call.
  // ApiService asks for the token before every authenticated request, so keep
  // the already decrypted values in process memory after the first read.
  static bool _accessLoaded = false;
  static bool _refreshLoaded = false;
  static String? _cachedAccess;
  static String? _cachedRefresh;
  static Future<String?>? _accessRead;
  static Future<String?>? _refreshRead;
  static int _generation = 0;

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: _keyAccess, value: access);
    await _storage.write(key: _keyRefresh, value: refresh);
    _generation++;
    _cachedAccess = access;
    _cachedRefresh = refresh;
    _accessLoaded = true;
    _refreshLoaded = true;
  }

  Future<void> saveKycEnrollmentToken(String token) async {
    await _storage.write(key: _keyKycEnrollment, value: token);
  }

  Future<String?> getKycEnrollmentToken() {
    return _storage.read(key: _keyKycEnrollment);
  }

  Future<void> clearKycEnrollmentToken() {
    return _storage.delete(key: _keyKycEnrollment);
  }

  Future<String?> getAccessToken() async {
    if (_accessLoaded) return _cachedAccess;
    final generation = _generation;
    final pending = _accessRead ??= _storage.read(key: _keyAccess);
    try {
      final value = await pending;
      if (generation != _generation) return _cachedAccess;
      _cachedAccess = value;
      _accessLoaded = true;
      return _cachedAccess;
    } finally {
      if (identical(_accessRead, pending)) _accessRead = null;
    }
  }

  Future<String?> getRefreshToken() async {
    if (_refreshLoaded) return _cachedRefresh;
    final generation = _generation;
    final pending = _refreshRead ??= _storage.read(key: _keyRefresh);
    try {
      final value = await pending;
      if (generation != _generation) return _cachedRefresh;
      _cachedRefresh = value;
      _refreshLoaded = true;
      return _cachedRefresh;
    } finally {
      if (identical(_refreshRead, pending)) _refreshRead = null;
    }
  }

  Future<void> resetAll() async {
    await _storage.delete(key: _keyAccess);
    await _storage.delete(key: _keyRefresh);
    await _storage.delete(key: _keyKycEnrollment);
    _generation++;
    _cachedAccess = null;
    _cachedRefresh = null;
    _accessLoaded = true;
    _refreshLoaded = true;
  }
}
