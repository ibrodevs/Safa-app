// lib/core/network/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../features/auth_module/register/data/models/register_request_model.dart';
import '../../features/auth_module/register/data/models/register_response_model.dart';
import 'model/api_exeptions_model.dart';

final class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static const String _baseUrl = 'http://164.92.182.171/api/';

  late final Dio _dio;

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
          handler.next(options);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<bool> _hasInternet() async {
    final r = await Connectivity().checkConnectivity();
    return r != ConnectivityResult.none;
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
}
