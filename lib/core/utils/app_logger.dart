import 'package:logger/logger.dart';

/// Логирование приложения.
///
/// Раньше это была глобальная переменная `final AppLogger = _AppLogger()`,
/// из-за чего линтер справедливо жаловался на имя не в lowerCamelCase.
/// Теперь это класс со статическими методами — все существующие вызовы
/// `AppLogger.d(...)` / `AppLogger.e(...)` работают без изменений.
class AppLogger {
  const AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
  );

  static void d(dynamic message) => _logger.d(message);

  static void i(dynamic message) => _logger.i(message);

  static void w(dynamic message) => _logger.w(message);

  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
