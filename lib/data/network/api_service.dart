import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../features/auth_module/register/data/models/register_request_model.dart';
import '../../features/auth_module/register/data/models/register_response_model.dart';
import '../services/secure_storage_service.dart';
import 'model/api_exeptions_model.dart';

final class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static const String _baseUrl = 'http://164.92.182.171/api/';

  final SecureStorageService _storage = SecureStorageService();
  late final Dio _dio;
  late final Dio _authDio;

  bool _refreshing = false;
  Completer<bool>? _refreshCompleter;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {
          'Accept': 'application/json',
        },
      ),
    );

    _authDio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      PrettyDioLogger(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        compact: true,
      ),
    );

    if (!kReleaseMode) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }

    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final connected = await _hasInternet();
          if (!connected) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.unknown,
                error: 'Нет подключения к интернету',
              ),
            );
          }

          if (_isAuthEndpoint(options)) {
            options.headers.remove('Authorization');
          } else {
            final access = await _storage.getAccessToken();
            if (access?.isNotEmpty == true) {
              options.headers['Authorization'] = 'Bearer $access';
            } else {
              options.headers.remove('Authorization');
            }
          }

          handler.next(options);
        },
        onError: (e, handler) async {
          final is403 = e.response?.statusCode == 403;
          final retried = e.requestOptions.extra['__retried__'] == true;

          if (!is403 || retried || _isAuthEndpoint(e.requestOptions)) {
            return handler.next(e);
          }

          final refresh = await _storage.getRefreshToken();
          if (refresh == null || refresh.isEmpty) {
            return handler.next(e);
          }

          try {
            if (_refreshing) {
              final ok =
              await (_refreshCompleter?.future ?? Future.value(false));
              if (!ok) return handler.next(e);
            } else {
              _refreshing = true;
              _refreshCompleter = Completer<bool>();
              try {
                final ok = await _refreshTokens(refresh);
                _refreshCompleter?.complete(ok);
              } catch (_) {
                _refreshCompleter?.complete(false);
                rethrow;
              } finally {
                _refreshing = false;
              }
            }

            final newAccess = await _storage.getAccessToken();
            final req = _cloneForRetry(e.requestOptions, newAccess);
            req.extra['__retried__'] = true;
            final cloned = await _dio.fetch<dynamic>(req);
            return handler.resolve(cloned);
          } catch (_) {
            await _storage.resetAll();
            await setBearer(null);
            return handler.next(e);
          }
        },
      ),
    );
  }

  Dio get dio => _dio;

  bool _isAuthEndpoint(RequestOptions o) {
    final p = o.path;
    return p.startsWith('users/token/') ||
        p.startsWith('users/register/') ||
        p.startsWith('users/verify/') ||
        p.startsWith('users/whatsapp-code/');
  }

  Future<bool> _hasInternet() async {
    final r = await Connectivity().checkConnectivity();
    return r != ConnectivityResult.none;
  }

  Future<void> setBearer(String? accessToken) async {
    if (accessToken?.isNotEmpty != true) {
      _dio.options.headers.remove('Authorization');
      return;
    }
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';
  }

  RequestOptions _cloneForRetry(
      RequestOptions original,
      String? accessToken,
      ) {
    final headers = Map<String, dynamic>.from(original.headers);
    if (accessToken?.isNotEmpty == true) {
      headers['Authorization'] = 'Bearer $accessToken';
    } else {
      headers.remove('Authorization');
    }
    headers.remove(HttpHeaders.contentLengthHeader);

    dynamic data = original.data;
    if (data is FormData) {
      final newForm = FormData();
      for (final f in data.fields) {
        newForm.fields.add(MapEntry(f.key, f.value));
      }
      for (final f in data.files) {
        newForm.files.add(MapEntry(f.key, f.value));
      }
      data = newForm;
    }

    return RequestOptions(
      path: original.path,
      method: original.method,
      baseUrl: original.baseUrl,
      data: data,
      queryParameters: Map<String, dynamic>.from(original.queryParameters),
      sendTimeout: original.sendTimeout,
      receiveTimeout: original.receiveTimeout,
      extra: Map<String, dynamic>.from(original.extra),
      headers: headers,
      responseType: original.responseType,
      contentType: original.contentType,
      followRedirects: original.followRedirects,
      persistentConnection: original.persistentConnection,
      validateStatus: original.validateStatus,
    );
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      return Map<String, dynamic>.from(jsonDecode(data));
    }
    throw ApiException('Некорректный формат ответа сервера');
  }

  ApiException _mapDioError(
      DioException e, {
        String fallback = 'Ошибка сети',
      }) {
    String message = fallback;
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map && data.isNotEmpty) {
      final firstKey = data.keys.first;
      final value = data[firstKey];
      if (value is List && value.isNotEmpty) {
        message = value.first.toString();
      } else if (value != null) {
        message = value.toString();
      }
    } else if (data is String && data.isNotEmpty) {
      message = data;
    } else if (statusCode != null) {
      message = 'Ошибка сервера $statusCode';
    }

    return ApiException(message, statusCode: statusCode);
  }

  Future<RegisterResponse> postRegister(RegisterRequest body) async {
    try {
      final formData = await body.toFormData();
      final resp = await _dio.post(
        'users/register/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final map = _asMap(resp.data);
      return RegisterResponse.fromJson(map);
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Ошибка регистрации');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<void> postWhatsappCode({required String phoneNumber}) async {
    try {
      await _dio.post(
        'users/whatsapp-code/',
        data: {
          'phone': phoneNumber,
        },
      );
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось отправить код в WhatsApp');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }
  Future<void> postDebugWhatsappCode({required String phoneNumber}) async {
    try {
      await _dio.post(
        'users/debug-code/',
        data: {
          'phone': phoneNumber,
        },
      );
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось отправить код в WhatsApp');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<void> postVerifyCode({
    required String phone,
    required String code,
  }) async {
    try {
      final resp = await _dio.post(
        'users/verify/',
        data: {
          'phone': phone,
          'code': code,
        },
      );
      final map = _asMap(resp.data);
      final access = map['access']?.toString() ?? '';
      final refresh = map['refresh']?.toString() ?? '';

      if (access.isEmpty || refresh.isEmpty) {
        throw ApiException('Некорректный ответ сервера');
      }

      await _storage.saveTokens(access: access, refresh: refresh);
      await setBearer(access);
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Неверный код подтверждения');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }


  Future<void> postToken({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final resp = await _authDio.post(
        'users/token/',
        data: {
          'phone_number': phoneNumber,
          'password': password,
        },
      );
      final map = _asMap(resp.data);
      final access = map['access']?.toString() ?? '';
      final refresh = map['refresh']?.toString() ?? '';
      if (access.isEmpty || refresh.isEmpty) {
        throw ApiException('Некорректный ответ сервера');
      }
      await _storage.saveTokens(access: access, refresh: refresh);
      await setBearer(access);
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Ошибка авторизации');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<bool> _refreshTokens(String refreshToken) async {
    try {
      final resp = await _authDio.post(
        'users/token/refresh/',
        data: {
          'refresh': refreshToken,
        },
      );
      if (resp.statusCode != 200 && resp.statusCode != 201) {
        return false;
      }
      final map = _asMap(resp.data);
      final access = map['access']?.toString() ?? '';
      final refresh = (map['refresh'] ?? refreshToken).toString();
      if (access.isEmpty) return false;
      await _storage.saveTokens(access: access, refresh: refresh);
      await setBearer(access);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<void> postSelfie({
    required String selfiePath,
    required String phone,
  }) async {
    try {
      if (selfiePath.isEmpty) {
        throw ApiException('Путь к файлу не задан');
      }
      if (phone.isEmpty) {
        throw ApiException('Номер телефона не задан');
      }

      final formData = FormData.fromMap({
        'phone': phone,
      });

      formData.files.add(
        MapEntry(
          'selfie_id_card',
          await MultipartFile.fromFile(
            selfiePath,
            filename: 'selfie.jpg',
          ),
        ),
      );

      await _dio.post(
        'users/selfie/',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось загрузить селфи');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<int> postCarrierWait({required String phone}) async {
    try {
      if (phone.isEmpty) {
        throw ApiException('Номер телефона не задан');
      }

      final resp = await _dio.post(
        'users/carrier-wait/',
        data: {
          'phone': phone,
        },
        options: Options(
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      final status = resp.statusCode ?? 0;
      if (status == 0) {
        throw ApiException('Некорректный ответ сервера');
      }

      if (status == 200) {
        try {
          final map = _asMap(resp.data);
          final access = map['access']?.toString() ?? '';
          final refresh = map['refresh']?.toString() ?? '';

          if (access.isNotEmpty && refresh.isNotEmpty) {
            await _storage.saveTokens(access: access, refresh: refresh);
            await setBearer(access);
          }
        } catch (_) {
        }
      }

      return status;
    } on DioException catch (e) {
      throw _mapDioError(
        e,
        fallback: 'Не удалось отправить запрос на ожидание',
      );
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }




  String? get currentAccessToken {
    final raw = _dio.options.headers['Authorization']?.toString();
    if (raw == null || raw.isEmpty) return null;
    return raw.startsWith('Bearer ') ? raw.substring(7) : raw;
  }
}
