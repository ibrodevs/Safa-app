import 'package:dio/dio.dart';
import 'package:dogo/data/network/api_service.dart';
import 'package:dogo/data/network/model/api_exeptions_model.dart';

import '../model/app_notification_model.dart';

class NotificationsRepository {
  NotificationsRepository(this._api);

  final ApiService _api;

  Future<List<AppNotificationModel>> getNotifications({
    required int page,
    required int pageSize,
    String? isRead,
  }) async {
    try {
      final resp = await _api.dio.get<dynamic>(
        'fcm/notifications/',
        queryParameters: <String, dynamic>{
          'page': page,
          'page_size': pageSize,
          if (isRead != null) 'is_read': isRead,
        },
      );

      final data = resp.data;

      final List<dynamic> rawList = data is List
          ? data
          : (data is Map<String, dynamic> && data['results'] is List)
          ? (data['results'] as List<dynamic>)
          : const <dynamic>[];

      return rawList
          .whereType<Map>()
          .map((e) => AppNotificationModel.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final d = e.response?.data;
      if (d is Map && d.isNotEmpty) {
        final firstKey = d.keys.first;
        final v = d[firstKey];
        if (v is List && v.isNotEmpty) {
          throw ApiException(v.first.toString(), statusCode: status);
        }
        if (v != null) throw ApiException(v.toString(), statusCode: status);
      }
      if (d is String && d.isNotEmpty) {
        throw ApiException(d, statusCode: status);
      }
      throw ApiException('Не удалось загрузить уведомления', statusCode: status);
    } catch (_) {
      throw ApiException('Не удалось загрузить уведомления');
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _api.dio.post<dynamic>(
        'fcm/notifications/$id/read/',
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final d = e.response?.data;
      if (d is Map && d.isNotEmpty) {
        final firstKey = d.keys.first;
        final v = d[firstKey];
        if (v is List && v.isNotEmpty) {
          throw ApiException(v.first.toString(), statusCode: status);
        }
        if (v != null) throw ApiException(v.toString(), statusCode: status);
      }
      if (d is String && d.isNotEmpty) {
        throw ApiException(d, statusCode: status);
      }
      throw ApiException('Не удалось отметить как прочитанное', statusCode: status);
    } catch (_) {
      throw ApiException('Не удалось отметить как прочитанное');
    }
  }
}
