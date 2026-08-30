import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth_module/register/data/models/register_request_model.dart';
import '../../features/auth_module/register/data/models/register_response_model.dart';
import '../../features/carrier_module/home/data/model/nearby_shipments_page.dart';
import '../../features/carrier_module/profile/data/model/carrier_day_stats.dart';
import '../../features/carrier_module/profile/data/model/carrier_profile_model.dart';
import '../../features/main_module/history/data/model/shipment_detail_model.dart';
import '../../features/main_module/history/data/model/shipment_history_models.dart';
import '../../features/main_module/map/data/model/delivery_reverse_geo.dart';
import '../../features/main_module/profile/data/model/profile_model.dart';
import '../../features/main_module/profile/data/model/support_model.dart';
import '../services/http_logger.dart';
import '../services/secure_storage_service.dart';
import '../../core/utils/app_logger.dart';
import 'model/api_exeptions_model.dart';

final class ApiService {
  static final ApiService instance = ApiService._internal();
  factory ApiService() => instance;

  static String get _baseUrl => const String.fromEnvironment(
    'DOGO_API_BASE_URL',
    defaultValue: 'https://api.safa-app.com/api/',
  );

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
        headers: const {'Accept': 'application/json'},
      ),
    );

    _authDio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Accept': 'application/json'},
      ),
    );
    // Formatting large GeoJSON bodies just for logs is expensive and may leak
    // credentials. The logger is useful in development, but must not execute in
    // profile/release builds.
    if (kDebugMode) {
      _dio.interceptors.add(HttpLoggerInterceptor());
      _authDio.interceptors.add(HttpLoggerInterceptor());
    }
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
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
          final status = e.response?.statusCode;
          final retried = e.requestOptions.extra['__retried__'] == true;
          final isAuthError = status == 401 || status == 403;

          if (!isAuthError || retried || _isAuthEndpoint(e.requestOptions)) {
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

  Future<void> setBearer(String? accessToken) async {
    if (accessToken?.isNotEmpty != true) {
      _dio.options.headers.remove('Authorization');
      return;
    }
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';
  }

  RequestOptions _cloneForRetry(RequestOptions original, String? accessToken) {
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

  ApiException _mapDioError(DioException e, {String fallback = 'Ошибка сети'}) {
    const userFriendly = 'ошибка. Обратитесь в поддержку';

    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (statusCode == 404 || (statusCode != null && statusCode >= 500)) {
      return ApiException(userFriendly, statusCode: statusCode);
    }
    if (statusCode == null) {
      final rawErr = e.error?.toString();
      if (rawErr != null && rawErr.trim().isNotEmpty) {
        return ApiException(rawErr, statusCode: null);
      }
      return ApiException(fallback, statusCode: null);
    }
    String message = fallback;

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
    } else {
      message = fallback;
    }

    final exception = ApiException(message, statusCode: statusCode);
    AppLogger.e('API Error [$statusCode]: $message', e, e.stackTrace);
    return exception;
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
      await _dio.post('users/whatsapp-code/', data: {'phone': phoneNumber});
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось отправить код в WhatsApp');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<void> postDebugWhatsappCode({required String phoneNumber}) async {
    try {
      await _dio.post('users/debug-code/', data: {'phone': phoneNumber});
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось отправить код в WhatsApp');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _dio.post('users/delete-account/');
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось удалить аккаунт');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<ProfileModel> patchProfile({
    required int? id,
    String? firstName,
    String? city,
    String? avatar,
    int? rate,
    int? clientRateCount,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (firstName != null) data['first_name'] = firstName;
      if (city != null) data['city'] = city;
      if (avatar != null) data['avatar'] = avatar;
      if (rate != null) data['rate'] = rate;
      if (clientRateCount != null) data['client_rate_count'] = clientRateCount;

      // Профиль редактируется только через self-endpoint. URL с ID на backend
      // предназначен исключительно для чтения и отклоняет PATCH.
      final resp = await _dio.patch('users/profile/', data: data);
      final map = _asMap(resp.data);
      return ProfileModel.fromJson(map);
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось обновить профиль');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  /// Загружает фото профиля на сервер.
  ///
  /// Backend хранит аватар как ImageField, поэтому запрос уходит multipart —
  /// PATCH с JSON-строкой файл не сохранит. [onProgress] отдаёт долю
  /// отправленных байт (0..1) для индикатора загрузки.
  Future<ProfileModel> uploadAvatar({
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final name = file.path.split(Platform.pathSeparator).last;
      final form = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(file.path, filename: name),
      });

      final resp = await _dio.patch(
        'users/profile/',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
        onSendProgress: (sent, total) {
          if (total <= 0) return;
          onProgress?.call((sent / total).clamp(0.0, 1.0));
        },
      );
      final map = _asMap(resp.data);
      return ProfileModel.fromJson(map);
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось загрузить фотографию');
    } catch (_) {
      throw ApiException('Не удалось загрузить фотографию');
    }
  }

  Future<void> postVerifyCode({
    required String phone,
    required String code,
  }) async {
    try {
      final resp = await _dio.post(
        'users/verify/',
        data: {'phone': phone, 'code': code},
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
        data: {'phone_number': phoneNumber, 'password': password},
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
        data: {'refresh': refreshToken},
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

      final kycToken = await _storage.getKycEnrollmentToken();
      if (kycToken == null || kycToken.isEmpty) {
        throw ApiException(
          'Сессия регистрации истекла. Зарегистрируйтесь повторно.',
        );
      }

      final formData = FormData.fromMap({
        'phone': phone,
        'kyc_token': kycToken,
      });

      formData.files.add(
        MapEntry(
          'selfie_id_card',
          await MultipartFile.fromFile(selfiePath, filename: 'selfie.jpg'),
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

      final kycToken = await _storage.getKycEnrollmentToken();
      if (kycToken == null || kycToken.isEmpty) {
        throw ApiException('Сессия регистрации истекла. Войдите с паролем.');
      }

      final resp = await _dio.post(
        'users/carrier-wait/',
        data: {'phone': phone, 'kyc_token': kycToken},
        options: Options(
          validateStatus: (code) => code != null && code >= 200 && code < 500,
        ),
      );

      final status = resp.statusCode ?? 0;
      if (status == 0) {
        throw ApiException('Некорректный ответ сервера');
      }

      if (status == 200) {
        final map = _asMap(resp.data);
        final access = map['access']?.toString() ?? '';
        final refresh = map['refresh']?.toString() ?? '';

        if (access.isNotEmpty && refresh.isNotEmpty) {
          await _storage.saveTokens(access: access, refresh: refresh);
          await _storage.clearKycEnrollmentToken();
          await setBearer(access);
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

  Future<ProfileModel> getProfile() async {
    try {
      final resp = await _dio.get('users/profile/');
      final map = _asMap(resp.data);
      return ProfileModel.fromJson(map);
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось загрузить профиль');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<CarrierProfileModel> getCarrierProfile() async {
    try {
      final resp = await _dio.get('users/profile/');
      final map = _asMap(resp.data);
      return CarrierProfileModel.fromJson(map);
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось загрузить профиль');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<DeliveryReverseGeo> getDeliveryReverseGeo({
    required double lat,
    required double lon,
  }) async {
    final response = await _dio.get(
      'delivery/geo/reverse/',
      queryParameters: {'lat': lat.toString(), 'lon': lon.toString()},
    );

    return DeliveryReverseGeo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
    String fallbackError = 'Ошибка сети',
  }) async {
    try {
      final resp = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
      );
      return _asMap(resp.data);
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: fallbackError);
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<List<Map<String, dynamic>>> getDeliveryAutocompleteRaw(
    String query,
  ) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final json = await getJson(
      'delivery/geo/autocomplete/',
      queryParameters: {'q': q},
      fallbackError: 'Не удалось выполнить поиск адреса',
    );

    final results = json['results'];
    if (results is! List) {
      return const [];
    }

    return results
        .whereType<Map>()
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<CarrierDayStats> getCarrierStatsForDate(DateTime date) async {
    String fmtDate(DateTime d) {
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    }

    try {
      final resp = await _dio.get(
        'delivery/stats/',
        queryParameters: {'date': fmtDate(date)},
      );
      final map = _asMap(resp.data);
      return CarrierDayStats.fromJson(map);
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось загрузить статистику');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<Map<String, dynamic>> createShipment({
    required String title,
    required String description,
    required List<Map<String, dynamic>> stops,
    bool returnToStart = false,
    String serviceType = 'delivery',
  }) async {
    try {
      final resp = await _dio.post(
        'delivery/shipments/',
        data: {
          'title': title,
          'service_type': serviceType,
          'description': description,
          'stops': stops,
          'return_to_start': returnToStart,
        },
      );
      return _asMap(resp.data);
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось создать доставку');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<Map<String, dynamic>> getShipmentQuote({
    required List<Map<String, dynamic>> stops,
    bool returnToStart = false,
  }) async {
    try {
      final resp = await _dio.post(
        'delivery/shipments/quote/',
        data: {'stops': stops, 'return_to_start': returnToStart},
      );
      return _asMap(resp.data);
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось рассчитать стоимость');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<void> deleteShipment(int id) async {
    try {
      await _dio.delete('delivery/shipments/$id/');
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось отменить доставку');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<void> patchShipmentStatus(int id, {required String status}) async {
    try {
      await _dio.post(
        'delivery/shipments/$id/set_status/',
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось сменить статус');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<ShipmentHistoryPage> getShipmentHistory({
    required int page,
    required int pageSize,
  }) async {
    try {
      final resp = await _dio.get(
        'delivery/shipments/history/',
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      final map = _asMap(resp.data);
      return ShipmentHistoryPage.fromJson(map);
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось загрузить историю доставок');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<ShipmentDetail> getShipmentDetail(int id) async {
    try {
      final resp = await _dio.get('delivery/shipments/$id/');
      final map = _asMap(resp.data);
      return ShipmentDetail.fromJson(map);
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось загрузить детали доставки');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<NearbyShipmentsPage> getNearbyShipments({
    required double lat,
    required double lon,
  }) async {
    try {
      final resp = await _dio.get(
        'delivery/shipments/nearby/',
        queryParameters: {'lat': lat, 'lon': lon},
      );
      final map = _asMap(resp.data);
      return NearbyShipmentsPage.fromJson(map);
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось загрузить ближайшие заказы');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<void> postCarrierPosition({
    required double lat,
    required double lon,
  }) async {
    try {
      await _dio.post('delivery/position/', data: {'lat': lat, 'lon': lon});
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось обновить позицию');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<ShipmentDetail> advanceShipment(int id) async {
    try {
      final resp = await _dio.post('delivery/shipments/$id/advance/');
      final map = _asMap(resp.data);
      return ShipmentDetail.fromJson(map);
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось перейти к следующей точке');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<ShipmentDetail> acceptShipment(int id) async {
    try {
      final resp = await _dio.post('delivery/shipments/$id/accept/');
      final map = _asMap(resp.data);
      return ShipmentDetail.fromJson(map);
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось принять заказ');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<Map<String, dynamic>> postFcmRegister({
    required String token,
    required String platform,
  }) async {
    try {
      final resp = await _dio.post(
        'fcm/register/',
        data: {'token': token, 'platform': platform},
      );
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      if (data is String) {
        return Map<String, dynamic>.from(jsonDecode(data));
      }
      return const {};
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final uri = (e.response?.requestOptions ?? e.requestOptions).uri;
      throw ApiException(
        'FCM_REGISTER_${status ?? 'ERR'} @ $uri: ${body is String ? body : (e.message ?? 'Ошибка сети')}',
        statusCode: status,
      );
    }
  }

  Future<Map<String, dynamic>> postPendingKycFcmRegister({
    required String token,
    required String platform,
  }) async {
    final kycToken = await _storage.getKycEnrollmentToken();
    if (kycToken == null || kycToken.isEmpty) {
      throw ApiException('Сессия регистрации специалиста истекла');
    }
    try {
      final resp = await _dio.post(
        'fcm/register-kyc/',
        data: {'token': token, 'platform': platform, 'kyc_token': kycToken},
      );
      return _asMap(resp.data);
    } on DioException catch (e) {
      throw _mapDioError(
        e,
        fallback: 'Не удалось включить уведомления о проверке профиля',
      );
    }
  }

  Future<Map<String, dynamic>> getShipments({
    int page = 1,
    int pageSize = 20,
  }) async {
    final resp = await dio.get(
      'delivery/shipments/',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    if (resp.data is Map<String, dynamic>) {
      return resp.data as Map<String, dynamic>;
    }
    if (resp.data is Map) return Map<String, dynamic>.from(resp.data as Map);
    throw ApiException('Некорректный ответ delivery/shipments/');
  }

  String? get currentAccessToken {
    final raw = _dio.options.headers['Authorization']?.toString();
    if (raw == null || raw.isEmpty) return null;
    return raw.startsWith('Bearer ') ? raw.substring(7) : raw;
  }

  Future<SupportModel> getSupport() async {
    try {
      final resp = await _dio.get('delivery/support/');
      final map = _asMap(resp.data);
      return SupportModel.fromJson(map);
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось загрузить данные поддержки');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }

  Future<String> getPrivacyPolicy() async {
    try {
      final resp = await _dio.get('delivery/privacy/');
      final map = _asMap(resp.data);
      final content = map['content']?.toString();
      if (content != null && content.trim().isNotEmpty) {
        return content.trim();
      }
      throw ApiException('Пустой ответ');
    } on DioException catch (e) {
      throw _mapDioError(e, fallback: 'Не удалось загрузить политику конфиденциальности');
    } catch (_) {
      throw ApiException('Непредвиденная ошибка');
    }
  }
}
