import 'package:flutter_dotenv/flutter_dotenv.dart';

final class FinikConfig {
  static String get apiKey =>
      dotenv.env['FINIK_API_KEY'] ?? '';

  static String get accountId =>
      dotenv.env['FINIK_ACCOUNT_ID'] ?? '';

  static bool get isBeta =>
      (dotenv.env['FINIK_BETA'] ?? 'false').toLowerCase() == 'true';

  static String get itemNameEn =>
      dotenv.env['FINIK_ITEM_NAME_EN'] ?? 'Delivery payment';
}
