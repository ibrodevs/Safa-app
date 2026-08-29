final class FinikConfig {
  const FinikConfig._();

  static const apiKey = String.fromEnvironment(
    'FINIK_API_KEY',
    defaultValue: 'rqtiBYolno7C8Ofu6wq044ITEwFZFkoL8yMe8GvU',
  );

  static const isBeta = bool.fromEnvironment('FINIK_BETA', defaultValue: false);

  static const itemNameEn = String.fromEnvironment(
    'FINIK_ITEM_NAME_EN',
    defaultValue: 'Safa delivery payment',
  );
}
