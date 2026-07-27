import 'dart:io';

import 'package:dio/dio.dart';

import '../../data/network/model/api_exeptions_model.dart';

/// Текст сетевой ошибки из ТЗ §18 — единственная формулировка для офлайна.
const String kOfflineErrorMessage =
    'Не удалось подключиться к серверу. '
    'Проверьте интернет и попробуйте снова.';

const String _kGenericErrorMessage = 'Что-то пошло не так. Попробуйте ещё раз.';

/// Превращает любую ошибку в текст, который можно показать пользователю.
///
/// Никогда не возвращает stack trace, HTML-ответ backend, `DioException [...]`
/// или `ApiException(500, ...)`. Раньше провайдеры делали `e.toString()`,
/// и пользователь видел ровно это.
String friendlyErrorMessage(Object? error, {String? fallback}) {
  final resolvedFallback = fallback ?? _kGenericErrorMessage;

  if (error == null) return resolvedFallback;

  if (error is SocketException || error is HttpException) {
    return kOfflineErrorMessage;
  }

  if (error is DioException) {
    return _fromDio(error, resolvedFallback);
  }

  if (error is ApiException) {
    // Отсутствие statusCode ещё не означает офлайн: слой API бросает
    // ApiException без кода и для «Непредвиденной ошибки», и для валидных
    // сообщений вроде «Неверный код из WhatsApp». Про офлайн знают только
    // DioException и SocketException выше.
    return _sanitize(error.message) ??
        _fromStatusCode(error.statusCode) ??
        resolvedFallback;
  }

  if (error is String) {
    return _sanitize(error) ?? resolvedFallback;
  }

  return resolvedFallback;
}

String _fromDio(DioException error, String fallback) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Сервер не отвечает. Проверьте связь и попробуйте снова.';
    case DioExceptionType.connectionError:
    case DioExceptionType.unknown:
      return kOfflineErrorMessage;
    case DioExceptionType.cancel:
      return 'Запрос отменён.';
    case DioExceptionType.badCertificate:
      return kOfflineErrorMessage;
    case DioExceptionType.badResponse:
      return _fromStatusCode(error.response?.statusCode) ?? fallback;
  }
}

String? _fromStatusCode(int? statusCode) {
  if (statusCode == null) return null;
  if (statusCode == 401 || statusCode == 403) {
    return 'Сессия истекла. Войдите в аккаунт заново.';
  }
  if (statusCode == 404) return 'Данные не найдены.';
  if (statusCode == 408 || statusCode == 504) {
    return 'Сервер не отвечает. Попробуйте позже.';
  }
  if (statusCode == 429) {
    return 'Слишком много запросов. Подождите немного.';
  }
  if (statusCode >= 500) {
    return 'Сервер временно недоступен. Попробуйте позже.';
  }
  return null;
}

/// Отбрасывает технические сообщения: HTML, JSON, обёртки исключений,
/// многострочные трейсы и слишком длинные тексты.
String? _sanitize(String? raw) {
  final message = raw?.trim();
  if (message == null || message.isEmpty) return null;

  if (message.startsWith('<') ||
      message.startsWith('{') ||
      message.startsWith('[')) {
    return null;
  }

  if (message.contains('Exception') ||
      message.contains('Error:') ||
      message.contains('#0 ') ||
      message.contains('package:')) {
    return null;
  }

  if (message.contains('\n')) return null;
  if (message.length > 160) return null;

  return message;
}
